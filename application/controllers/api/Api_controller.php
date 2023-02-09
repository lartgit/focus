<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Controller creado solamente para evitar el control de acceso al menu.
 * 
 * @author AGB 2022
 * @package Focus
 */
class Api_controller extends Entity_Admin
{
    public function check_user_access()
    {
        return $this->check_user_logued();;
    }
}
