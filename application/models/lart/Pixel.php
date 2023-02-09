<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Pixel extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'pixel';
    protected static $_display_name = 'Descargar Grilla de Píxeles';
    protected static $_plural_name = 'Descargar Grilla de Píxeles';
    protected static $_display_column = 'id';

    /** Variables Públicas del Model */
    public $center_latitude;
    public $center_longitude;
    public $set_id;
    public $the_geom;

    /** Variables private */
    // public $versions;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

   public function related_with(){
       return NULL;
   }
//
    public static function references_class() {
        return Array('set_id' => 'Pixel_set');
    }

    public function required_variables() {
        return array_merge(parent::required_variables(),array('center_latitude', 'center_longitude', 'set_id', 'the_geom'));
    }

    public function is_deleteable() {
         if ( issempty( $this->pixels_field_use() ) )
            return true;
        else
            return false;
    }

    public function pixels_field_use(){

        //Falta definir el modelo de pixels_field_use
        return Array();
    }

    public function download_as_shp($record_limit, $set_id)
    {
        $output = array();
        $return = '';
        $file_name = $this->user->name . uniqid('-');

        #Traemos los datos del archivo Config y Database para correr el proceso en el pgsql2shp
        $path = $this->config->item('upload_path');
        $dbname = $this->db->database;
        $dbusername = $this->db->username;
        $dbpassword = $this->db->password;
        $dbhost = $this->db->hostname;

        #Ejecutamos el comando pgsql2shp
        exec("cd '$path' && pgsql2shp -u $dbusername -h $dbhost -P $dbpassword -p 5432 -f '$file_name' $dbname \"SELECT * FROM pixel WHERE set_id = $set_id LIMIT $record_limit\"", $output, $return);

        $archarem = array();
        $zip = new ZipArchive;
        $ret = $zip->open("$path/$file_name.zip", ZIPARCHIVE::CREATE);
        if ($ret === true) {
            $archarem[] = "$path/$file_name.zip";
            $handle = opendir($path);
            while ($handle && false !== ($f = readdir($handle))) {
                if ($f != '.' && $f != '..' && substr($f, 0, strlen($file_name)) === $file_name) {
                    $filePath = "$path/$f";

                    if (is_file($filePath) /*&& (substr($f, 0, 6) == 'output')*/) {
                        $zip->addFile($filePath, $f);
                        $archarem[] = $filePath;
                    }
                }
            }
            $zip->close();
        } else {
            die('failed');
        }

        header("Content-Type: application/zip");
        header("Content-Disposition: attachment; filename=shapefile.zip");
        header("Content-Length: " . filesize("$path/$file_name.zip"));

        readfile("$path/$file_name.zip");

        foreach($archarem as $file) unlink($file);
    }
}

