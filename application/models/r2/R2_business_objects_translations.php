<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description Business_objects_translations
 *
 *
 *
 */
class R2_Business_Objects_Translations extends R2_Dbobject {

    /** Variables Static de Configuración del Model */
    protected static $_table_schema = 'public'; // Nombre de la tabla (responsabilidad de las subclases)
    protected static $_table_name = 'business_objects_translations'; // Nombre de la tabla (responsabilidad de las subclases)
    protected static $_display_name = 'Traduccion'; // Nombre con el que se muestra la clase (dejar vacío para clases abstractas).
    protected static $_plural_name = 'Traducciones'; // Nombre en plural con el que se muestra la clase (dejar vacío para clases abstractas).
    // protected static $_active_column = 'null';
    protected static $_display_column = 'current_name';
    protected static $_log_activity = FALSE;

    /* Public Vars */
    public $current_name;
    public $spanish_translation;
    public $english_translation;
    public $ts;

    public function __construct() {
        parent::__construct();
    }

    public function get_all($select_lang) {
        $this->db->from(self::$_table_schema . '.' . self::$_table_name);
        $this->db->order_by('current_name', 'asc');
        return $this->db->get()->result();
    }

    public function not_translate_rows($select_lang) {
        return $this->db
                        ->where("$select_lang", '')
                        ->get(self::$_table_schema . '.' . self::$_table_name)
                        ->result();
    }

    public function translate_rows($select_lang) {
        return $this->db
                        ->where("$select_lang !=", '')
                        ->get(self::$_table_schema . '.' . self::$_table_name)
                        ->result();
    }

    public function update_lang_file($select_lang) {
        $result = $this->translate_rows($select_lang);
        $data = array();
        foreach ($result as $row) {
            if (!empty($row->$select_lang)) {
                $data[$row->current_name] = $row->$select_lang;
            }
        }

        $file = fopen(APPPATH . 'language/' . str_replace('_translation', '', $select_lang) . '/translations_lang.php', 'w');
        fwrite($file, '<?php $lang = ' . var_export($data, true) . '; ?>');

        fclose($file);
    }

    public function add_language($data) {
        $language = strtolower(trim($data['new_lang'])) . '_translation';

        $tabla = $this->class_table_columns_postgres();

        $fields = array();

        foreach ($tabla as $each) {
            $fields[] = $each->name;
        }

        if (in_array($language, $fields)) {
            $this->errors[] = "El Idioma ya existe";
            return;
        } else {
            $query = "ALTER TABLE public.business_objects_translations ADD $language varchar(100)";
            return $this->db->query($query);
        }
    }

}
