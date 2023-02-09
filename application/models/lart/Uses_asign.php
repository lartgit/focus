<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 */

class Uses_asign extends CI_Model {

   /**  Variables Static de Configuración del Model */

   /** Construct */
    public function __construct() {
        parent::__construct();
    }


    /**
     *
     * @param $campo
     * @param $lote
     * @param $grupo
     * @return field_id
     */
    public static function get_field_id_and_asign_uses( $farm, $field, $group, $version_id, $date_declared, $use_concrete, $use_from, $use_to ){
        $CI = get_instance();

        $query = "SELECT fields.id FROM fields
                        JOIN farms fa on fa.id = fields.farm_id AND fa.version_id = $version_id AND upper(fa.name) = upper(".pg_escape_literal($farm).")
                        WHERE upper(fields.name) = upper(".pg_escape_literal($field).")
                        AND upper(fields.group_name) = upper(".pg_escape_literal($group).")";

        $db_data = $CI->db->query($query)->result();

        if (empty($db_data)) {
            return false;
        } else {
            $use_id = $use_concrete;

            $field_id = $db_data[0]->id;

            $str_use_from = $use_from!==FALSE?"'$use_from'":'NULL';
            $str_use_to = $use_to!==FALSE?"'$use_to'":'NULL';

            // Me fijo si ya hay una declaracion para ese lote en ese rango de fechas
            $declarations_concrete_data = $CI->db->query("
                SELECT declarations_concrete.id AS declaration_concrete_id, declaration_id
                  FROM declarations_concrete
                  JOIN declarations ON declarations.id = declarations_concrete.declaration_id
                 WHERE tsrange(date_from, date_to, '[]') && tsrange($str_use_from, $str_use_to, '[]')
                   AND field_id = $field_id
            ")->result();

            $declarations = array();
            foreach ($declarations_concrete_data as $decl) {
                $declarations[$decl->declaration_id] = true;
                $CI->db->query("DELETE FROM declarations_concrete WHERE id = $decl->declaration_concrete_id");
            }
            foreach (array_keys($declarations) as $decl) {
                // me fijo si la declaracion esta huérfana
                $q = $CI->db->query("SELECT count(*) FROM declarations_concrete WHERE declarations_concrete.declaration_id = $decl")->result();

                if(count($q) && $q[0]->count == 0) {
                    $CI->db->query("DELETE FROM declarations WHERE id = $decl");
                }
            }

            $declared_id = static::set_declarations( $field_id, $date_declared, $use_id );

            static::insert_declaration_concrete( $use_id, $declared_id, $use_from, $use_to );
        }

        return true;
    }

    public static function check_field_exists( $farm, $field, $group, $version_id ){
        $CI = get_instance();

        $query = "
            SELECT fields.id
              FROM fields
              JOIN farms fa on fa.id = fields.farm_id
             WHERE upper(fields.name) = upper(".pg_escape_literal($field).")
               AND upper(fa.name) = upper(".pg_escape_literal($farm).")
               AND upper(fields.group_name) = upper(".pg_escape_literal($group).")
               AND fa.version_id = $version_id
        ";

        $db_data = $CI->db->query($query)->result();

        if (empty($db_data))
            return false;

        return true;

    }

    /**
     * Chequea que exista el uso concreto
     * Sino encuentra el uso return
     * @param $uses nombre del uso concreto a asignar
     * @return $id | false
     */
    public static function get_concrete_use($uses){
        $CI = get_instance();

        $db_data = $CI->db->query("SELECT id FROM use_concretes where name = '$uses' ")->result();

        if (empty($db_data)) {
            return false;
        }

        return $db_data[0]->id;
    }


    /**
     * Inserta la declaracion, SOLO SI se encontro el uso concreto a asignar
     *
     * @param $field_id
     * @param $declaration_date
     * @return $id | false
     */
    public static function set_declarations($field_id, $declaration_date, $use){
        $CI = get_instance();

        $declared = $CI->db->query("SELECT id FROM declarations where date = '$declaration_date' AND field_id =  $field_id ")->result();

        if (count($declared)) {
            return $declared[0]->id;
        }

        $ret = $CI->db->query("INSERT INTO declarations (date, field_id) values ('$declaration_date', $field_id ) ");

        if (!$ret) {
            return FALSE;
        }

        return $CI->db->insert_id();

    }

    /**
     * insert declarations concrete
     *
     * @param $use_concrete_id
     * @param $declaration_id
     * @param $concrete_from_date
     * @param $concrete_to_date
     * @return $id | false
     */
    public static function insert_declaration_concrete($use_concrete_id, $declaration_id, $concrete_from_date, $concrete_to_date){
        $CI = get_instance();
        $query = "";

        if ( $concrete_from_date == '' && $concrete_to_date == '' ) {
            $query = "INSERT INTO declarations_concrete (use_concrete_id, declaration_id ) VALUES ($use_concrete_id,$declaration_id ) ";
        }
        else if($concrete_from_date == '' && $concrete_to_date != '')
        {
            $query = "INSERT INTO declarations_concrete (use_concrete_id, declaration_id, date_to) VALUES ($use_concrete_id,$declaration_id,'$concrete_to_date'::timestamp )";
        }
        else if($concrete_from_date != '' && $concrete_to_date == '')
        {
            $query = "INSERT INTO declarations_concrete (use_concrete_id, declaration_id, date_from) VALUES ($use_concrete_id, $declaration_id, '$concrete_from_date'::timestamp)";
        }
        else if($concrete_from_date != '' && $concrete_to_date != '')
        {
            $query = "INSERT INTO declarations_concrete (use_concrete_id, declaration_id, date_to, date_from) VALUES ($use_concrete_id, $declaration_id, '$concrete_to_date'::timestamp, '$concrete_from_date'::timestamp)";
        }

        $ret = $CI->db->query($query);

        if (!$ret) {
            return;
        }

        return $CI->db->insert_id();

    }

    /**
     * Deberia chequear antes de hacer el insert
     * que la fecha no se pise con una declaracion ya existente para ese lote, campo, version
     *
     * @param $concrete_from_date
     * @param $concrete_to_date
     */
    public static function check_field_uses_dates(){

    }
                  
    // ***************************
    // ***************************
    // ESTO ES LO QUE HARIAMOS SI HAY QUE INSERTAR USO DECLARADO
    // Con reglas de expansion temporal y bla bla bla
    //**************************
    //**************************
        // cursor.execute("SELECT id FROM use_declareds where name = '%s' " % use_declared_name)
        // if cursor.rowcount == 0:
        //     return False

        // use_declared_id = cursor.fetchone()[0]

        // #Ahora viene LA query
        // #esta query me devuelve los usos concretos que tengo que insertar en declarations_concrete

        // # print """SELECT use_concrete_id, month_from, month_to
        // #                FROM temporal_expansion_rules ter
        // #                JOIN regions r on r.id = ter.region_id
        // #                WHERE St_Intersects(the_geom, %s) AND use_declared_id = %s AND declaration_month = %s """ % (wkt, use_declared_id, declaration_date.month)

        // cursor.execute("SELECT use_concrete_id, month_from, month_to "+
        //                "FROM temporal_expansion_rules ter "+
        //                "JOIN regions r on r.id = ter.region_id "+
        //                "WHERE St_Intersects(the_geom, %s) AND use_declared_id = %s AND declaration_month = %s ",
        //                (AsIs(wkt), use_declared_id, declaration_date.month) )

        // if cursor.rowcount == 0:
        //     # "No hay reglas de expansion temporal para ese lote"
        //     return False

        // reglas = cursor.fetchall()

        // #inserto la declaracion
        // cursor.execute("INSERT INTO declarations (field_id, date, use_declared_id) VALUES (%s,%s,%s) RETURNING id", (field_id, declaration_date, use_declared_id))
        // declaration_id = cursor.fetchone()[0]

        // #tengo que procesar las reglas, reviso todas y me quedo con la regla mas nueva
        // for (use_concrete_id, month_from, month_to) in reglas:
        //     new_from = add_months(declaration_date, month_from)
        //     new_to   = add_months(declaration_date, month_to)
        //     #inserto el uso_concreto
        //     cursor.execute("INSERT INTO declarations_concrete (use_concrete_id, declaration_id, date_from, date_to) VALUES (%s,%s,%s,%s) RETURNING id",
        //                 (use_concrete_id, declaration_id,
        //                 new_from.replace(day = 1),
        //                 new_to.replace(day = calendar.monthrange(new_to.year, new_to.month)[1])))


}

