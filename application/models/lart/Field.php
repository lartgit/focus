<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Field extends R2_EntityModel
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'fields';
    protected static $_display_name = 'Descargar Shape Files de Lotes';
    protected static $_plural_name = 'Descargar Shape Files de Lotes';

    /** Variables Públicas del Model */
    public $name;
    public $date_from;
    public $date_to;
    public $the_geom;
    public $group_name; // Variable incluida para agregar el grupo que necesitan la gente de CREA

    /** Variables private */
    private $declarations;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }

    public function declarations()
    {
        if (!isset($this->declarations))
            $this->declarations = Declaration::where(array('field_id' => $this->id));

        return $this->declarations;
    }

    public function is_deleteable()
    {
        $referenced_id = Declaration::where(array('field_id' => $this->id));

        if (empty($referenced_id)) {
            return true;
        }

        return false;
    }

    public function farm_name()
    {
        if (isset($this->farm_name))
            return $this->farm_name;
        else
            return $this->farm()->name;
    }

    public function farm()
    {
        return Farm::find($this->farm_id);
    }

    public function filter_fields_by($date = false, $farms_id = array())
    {
        $where = array();

        if ($date) {
            $date = date('Y-m-d H:i:s', strtotime($date));
            // return $this->db->query("select * from fields where date_from <= '$date' AND COALESCE('$date' <= date_to, True)")->result();
            $where = array_merge($where, array('date_from <=' => "'$date'", 'date_to >=' => "'$date'"));
        }

        if (count($farms_id)) {
            $where = array_merge($where, array('farm_id IN' => '(' . join(',', $farms_id) . ')'));
        }

        if (count($where))
            return $this->where($where, FALSE);

        return $this->all_permitted();
    }

    public function datatable_to_shp($date, $folder, $farms)
    {

        $folder = trim($folder, '/');

        $output = array();
        $return = '';
        $file_name = $this->user->name . uniqid('-');

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $this->config->item('upload_path') . $folder;
        $dbname = $this->db->database;
        $dbusername = $this->db->username;
        $dbpassword = $this->db->password;
        $dbhost = $this->db->hostname;

        $where = ' 1=1 ';
        if ($date !== FALSE && $date !== '')
            $where .= " AND date_from <= '$date' AND COALESCE('$date' <= date_to, True) ";
        if ($farms !== FALSE && $farms !== '')
            $where .= " AND farm_id IN (" . join(',', $farms) . ") ";

        #Ejecutamos el comando pgsql2shp
        exec("cd $path && pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f \"$file_name\" \"$dbname\" \"SELECT name, date_from, date_to, the_geom FROM fields WHERE $where\"", $output, $return);

        #Retorno true o false y el error lo manejo en la view, para no pasar la salida standar de la terminal
        if ($return == 0) {
            return true;
        } else
            return false;
    }

    /*
    * Limito los registros porque el render de datatbles 
    * tarda mucho en manipular el DOM
    */
    public function all_limited($limit = 2000)
    {
        $this->db->limit($limit);
        return static::all_permitted();
    }

    public static function all_permitted()
    {
        $CI = get_instance();

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->join('farms', 'farms.id = farm_id');
            $CI->db->join('versions', 'versions.id = version_id');
            $CI->db->join('projects', 'projects.id = project_id');
            $CI->db->join('clients', 'clients.id = client_id');
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return static::all_orderby(static::class_display_column());
    }

    public static function get_use_query($version_id) {
        return get_instance()->db->query("SELECT 
            c2.name client,
            p2.name project,
            v.name \"version\",
            fi.group_name grupo,
            fa.name campo,
            fi.name lote,
            d.date fecha,
            dc.date_from usodesde,
            dc.date_to usohasta,
            uc.name uso
        FROM fields fi
        JOIN farms fa ON fa.id = fi.farm_id 
        JOIN versions v ON v.id = fa.version_id 
        JOIN projects p2 ON p2.id = v.project_id 
        JOIN clients c2 ON c2.id = p2.client_id 
        JOIN declarations d ON d.field_id = fi.id
        JOIN declarations_concrete dc ON dc.declaration_id = d.id
        JOIN use_concretes uc ON uc.id = dc.use_concrete_id 
        WHERE fa.version_id = $version_id");
    }
}
