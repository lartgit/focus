<?php

if (!defined('BASEPATH')) {
    exit('No direct script access allowed');
}

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Project extends R2_EntityModel
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'projects';
    protected static $_display_name = 'Proyecto';
    //protected static $_display_column = 'name';
    protected static $_plural_name = 'Proyectos';

    /** Variables Públicas del Model */
    public $name;
    public $client_id;
    public $parent_id;
    public $draw_tree;
    public $description;

    /** Variables private */
    private $sub_projects;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public static function references_class()
    {
        return array('client_id' => 'Client', 'parent_id' => 'Project');
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name', 'client_id'));
    }

    public function related_with()
    {
        return array($this->sub_projects(), $this->versions());
    }

    public function sub_projects()
    {
        if (!isset($this->sub_projects)) {
            $this->sub_projects = Project::where(array('parent_id' => $this->id));
        }
        return $this->sub_projects;
    }

    public function versions()
    {
        if (!isset($this->versions)) {
            $this->versions = Version::where(array('project_id' => $this->id));
        }
        return $this->versions;
    }

    /**
     *
     * Metodo Recursivo para devolver el objeto padre e hijos
     */
    public function recursivit_projects($list, $id = null)
    {

        $root = array();

        foreach ($list as $node) {
            if ($node->parent_id === $id) {
                $root[] = $node;
            }
        }

        foreach ($root as $each) {
            $each->versions = Version::where(array('project_id' => $each->id));
            $each->childs = $this->recursivit_projects($list, $each->id);
        }

        return $root;
    }

    /**
     * Metodo public que retorna el arbol dibujado
     * @param $tree array
     */
    public function spit_tree($tree, $div_id, $client_id = NULL)
    {

        if (empty($tree)) {
            return '';
        }

        $this->icon = Menu_Option::get_icon_for("Proyecto");

        $ret = "<ul id='$div_id'>";
        $tmp_tree = $this->build_tree($tree);
        // var_dump($tree);exit;
        $ret .= $this->html_tree($tmp_tree);

        $ret .= '</ul>';

        return $ret;
    }


    /**
     * 
     */
    public function build_tree($tree)
    {
        $ret_client = array();
        foreach ($tree as $each) {
            if (!isset($ret_client[$each->client_id])) $ret_client[$each->client_id] = array();
            $ret_client[$each->client_id][] = $each;
        }

        return $ret_client;
    }

    private function html_tree($tree)
    {
        foreach ($tree as $client_id => $each) {

            $client_name = $this->get_client_name($client_id);

            $this->draw_tree .= "<li class='client_node'  data-placement='bottom' data-toggle='tooltip'>$this->icon<a href='#'>" . 'Cliente: ' . $client_name . "</a>";
            $this->draw_tree .= '<ul>';

            $this->recursivit_tree($each);

            $this->draw_tree .= '</ul>';
            $this->draw_tree .= '</li>';
        }


        return $this->draw_tree;
    }

    /**
     *
     * Metodo que dibuja el arbol de proyectos.
     *
     * @param $tree array
     * return string con el html
     */
    private function recursivit_tree($tree, $client_id = NULL)
    {
        $client_name;
        foreach ($tree as $each) {
            $this->draw_tree .= "<li class='project_node'  data-placement='bottom' data-toggle='tooltip'>$this->icon<a href='#' class='ref' data-name='$each->name' data-value='$each->id'>" . '<b>Proy:</b> ' . $each->name . "</a>";

            if (!empty($each->childs) || !empty($each->versions)) {
                $this->draw_tree .= '<ul>';
                if (!empty($each->childs)) {
                    $this->recursivit_tree($each->childs);
                }

                if (!empty($each->versions)) {
                    foreach ($each->versions as $version) {
                        $this->draw_tree .= "<li ><a class='version_node' href='#' data-placement='bottom' data-toggle='tooltip' class='ref-ver' data-name='$version->name' data-value='$version->id'>$version</a></li>";
                    }
                }

                $this->draw_tree .= '</ul>';
            }

            $this->draw_tree .= '</li>';
        }
        return $this->draw_tree;
    }

    /**
     *
     */
    public function validate()
    {

        if ($this->id && $this->parent_id) {
            $tmp_id = $this->parent_id;
            while (!is_null($tmp_id) || $tmp_id != '') {
                if ($tmp_id == (int) $this->id) {
                    $this->errors('Referencia ciclica');
                    break;
                }

                $tmp_id = $this->find_my_father($tmp_id);
            }
        }

        return parent::validate();
    }

    protected function validate_name_already_used()
    {
        $tmp = static::where(array('name' => $this->name, 'client_id' => $this->client_id));

        //Caso nuevo reg
        if (!$this->id && !empty($tmp)) {
            $this->errors[] = "El nombre $this->name ya está siendo utilizado";
        }

        //Caso edit
        foreach ($tmp as $each) {
            if ($this->id && ($each->id !== $this->id)) {
                $this->errors[] = "El nombre $this->name ya está siendo utilizado";
            }
        }
    }

    public function before_save()
    {
        //Re-implemento el before_save para cambiar el client_id de los sub-proyectos.
        parent::before_save();
        $instances = $this->all();
        $this->change_child_clients($this->recursivit_projects($instances, $this->id), $this->client_id);
        return true;
    }

    private function find_my_father($parent)
    {

        $ancestor = $this->where(array('id' => $parent));

        return $ancestor[0]->parent_id;
    }

    private function change_child_clients($list, $instance)
    {

        if (!empty($list)) {
            foreach ($list as $each) {
                $each->client_id = $instance;
                $each->save();
                if (!empty($each->childs)) {
                    $this->change_child_clients($each->childs, $instance);
                }
            }
        }
    }

    /**
     * Description: recibe el client_id del projecto y devuelve el nombre
     *
     * @param int client_id
     * @return string client name
     */
    private function get_client_name($client_id)
    {
        $clients = Client::find($client_id);
        return $clients->name;
    }


    public static function all_permitted()
    {
        $CI = get_instance();

        $CI->db->join('clients', 'clients.id = client_id');
        $CI->db->select('clients.name as client_name');

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        return parent::all_permitted();
    }
}
