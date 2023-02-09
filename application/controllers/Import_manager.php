<?php

if (!defined('BASEPATH'))
   exit('No direct script access allowed');

/**
 * Description:
 * Controller para administrar los valores de importacion
 * para correrlo: php index.php admin import_manager import
 *
 * @author  ABayerl 2016
 * @package <Da>
 */
class Import_manager extends CI_Controller {

    public function __construct() {
        parent::__construct();
        $this->load->database();
    }

    public function import() {
        set_time_limit(0);

        //Me fijo todas las configuraciones
        $configuraciones = Import_data::where(array('start_process_at is' => 'NULL'), false);

        // Se itera por cada proceso de importación y se realiza la misma.
        foreach ($configuraciones as $each) {
            $each->start_process_at = date('Y-m-d H:i:s');
            // $each->save();

            // Se inicia una transacción:
            $this->db->trans_start();

            // Se delega en el modelo hacer la importación del archivo
            $model = $each->model_name;
            $res = Temporal_expansion_rule::do_import($each->path,$each->version_id);

            // Se revisan si ocurrieron erores durante la importación:
            if (count($model::$import_errors) !== 0) {
                echo implode("\n", $model::$import_errors) . "\n";
                $each->comments = implode("<br/>", $model::$import_errors) . "<br/>";
            }

            // Se establece el resultado
            if ($res === true) {
                if (count($model::$import_errors) !== 0) {
                    $each->set_result_successfull_with_warnings();
                } else {
                    $each->set_result_successfull();
                }
            } else {
                $each->set_result_with_error("Error: " . $res);
            }

            // Se finaliza la transacción
            $this->db->trans_complete();

            // Se graba el proceso
            $each->end_process_at = date('Y-m-d H:i:s');
            $each->save();
        }

        //Si hubo algo que se importo, actualizo los balances de las companias de agregacion
        //Tal vez solo deba hacerlo si alguna de ellas fue de balances.
        // RESPETAR EL ORDEN DE LOS LLAMADOS A LAS FUNC!!!!!!!
        if(count($configuraciones) > 0){
            // /*Agregamos esta funcion al postgres para hacer el updste de los trades de las cuentas de resultados.*/
         //    Balance::update_results_accounts();
         //    Balance::update_aggregation_companies();
        }

        exit(0);
    }


    public function import_uses_from_csv_file(){
        set_time_limit(0);
        $this->db->trans_strict(FALSE);

        $process_to_run =  Import_data::where(array('end_process_at' => NULL));

        // var_dump($process_to_run);exit;
        if (!empty($process_to_run)) {
            foreach ($process_to_run as $process) {
                $instance = Import_data::find($process->id);
                $instance->start_process_at = date('Y-m-d H:i:s');
                $this->db->trans_begin();
                $ret = Import_data::do_import_from_csv($process->path, $process->version_id);
                if ($ret === true ){
                    $instance->comments = json_encode(array("Usos Asignados con exito "));
                    $instance->result = 'success';
                    $this->db->trans_commit();
                }
                else{
                    $instance->comments = json_encode($ret);
                    $instance->result = 'errors found';
                    $this->db->trans_rollback();
                }
                $instance->end_process_at = date('Y-m-d H:i:s');
                $this->db->trans_complete();
                $instance->save();
            }
        }

        exit(0);
    }
}
