<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Use_concret extends R2_DbObject {

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'use_concretes';
    protected static $_display_name = 'uso_concreto';
    protected static $_plural_name = 'usos_concretos';
    protected static $_display_column = 'name';

    /** Variables Públicas del Model */
    public $name;
    public $temporal_expansion_rules;

    /** Construct */
    public function __construct() {
        parent::__construct();
    }

    public function required_variables() {
        return array_merge(parent::required_variables(), array('name'));
    }

    public function related_with() {
        return array($this->temporal_expansion_rules());
    }

    public function is_deleteable() {
        /*
        if ($this->temporal_expansion_rules()) {

            return false;
        }
        */

        return true;
    }

    public function temporal_expansion_rules() {
        if (!isset($this->tmporal_expansion_rules))
            $this->temporal_expansion_rules = Temporal_expansion_rule::where(Array('use_concrete_id' => $this->id));

        return $this->temporal_expansion_rules;
    }

}
