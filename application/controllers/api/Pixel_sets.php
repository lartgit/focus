<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * @author AGB 2022
 * @package Focus
 */
class Pixel_sets extends Api_controller
{
    public function for_imagen_type()
    {
        $imagen_type_id = $this->input->get("imagen_type_id");
        if (!$imagen_type_id) {
            echo "[]";
            return;
        }

        echo json_encode(Pixel_set::where(["imagen_type_id" => $imagen_type_id]));
    }
}
