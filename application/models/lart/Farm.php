<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 * @author Yuri Zoolander 2015
 * @package Focus
 */
class Farm extends R2_EntityModel
{

    /**  Variables Static de Configuración del Model */
    protected static $_table_name = 'farms';
    protected static $_display_name = 'Campo';
    protected static $_plural_name = 'Campos';

    /** Variables Públicas del Model */
    public $name;
    public $version_id;
    public $code;
    public $draw_tree;
    public $new_draw_tree;

    /** Variables private */
    private $fields;

    /** Construct */
    public function __construct()
    {
        parent::__construct();
    }

    public static function references_class()
    {
        return array('version_id' => 'Version');
    }

    public function required_variables()
    {
        return array_merge(parent::required_variables(), array('name'));
    }

    public function fields()
    {
        if (!isset($this->fields))
            $this->fields = Field::where(array('farm_id' => $this->id));

        return $this->fields;
    }

    public function related_with()
    {
        return array($this->fields());
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
            $each->versions = $this->projects_versions($each->id);

            $each->childs = $this->recursivit_projects($list, $each->id);
        }

        return $root;
    }

    public function projects_versions($project_id)
    {
        $versions = array();

        $versions = Version::where_in('project_id', $project_id);

        return $versions;
    }

    /**
     * Metodo public que retorna el arbol dibujado
     * @param $tree array 
     */
    public function spit_tree($tree, $div_id)
    {

        if (empty($tree)) {
            return '';
        }

        $ret = "<ul id='$div_id'>";

        $ret .= $this->recursivit_tree($tree);

        $ret .= '</ul>';

        return $ret;
    }

    /**
     *
     * Metodo que dibuja el arbol de proyectos.
     *
     * @param $tree array 
     * return string con el html 
     */
    private function recursivit_tree($tree)
    {

        foreach ($tree as $each) {
            $this->draw_tree .= "<li><a href='#'>" . $each->name . "</a>";

            if (!empty($each->versions)) {
                $this->draw_tree .= "<ul> <li><a href='#'>Versiones</a>";
                $this->draw_tree .= '<ul>';
                $this->draw_tree .= $this->recursivit_tree_versions($each->versions);
                $this->draw_tree .= '</ul>';
                $this->draw_tree .= '</li></ul>';
            }

            if (!empty($each->childs)) {
                $this->draw_tree .= '<ul>';
                $this->recursivit_tree($each->childs);
                $this->draw_tree .= '</ul>';
            }



            $this->draw_tree .= '</li>';
        }

        return $this->draw_tree;
    }

    private function recursivit_tree_versions($tree)
    {
        foreach ($tree as $each) {
            $this->draw_tree .= "<li><a href='#' class='ref' data-name='$each->name' data-value='$each->id'>" . $each->name . "</a>";
        }
        return $this->new_draw_tree;
    }

    //extiendo all_permited para agregarle un filtro de limit
    public static function all_permitted_filtered($limit)
    {
        $CI = get_instance();

        if ($limit)
            $CI->db->limit($limit);

        $CI->db->join('versions', 'versions.id = version_id');
        $CI->db->join('projects', 'projects.id = project_id');
        $CI->db->join('clients', 'clients.id = client_id');

        if (!in_array($CI->user->id, User::$_SuperUsers)) {
            $CI->db->where('organization_id', $CI->user->organization_id);
        }

        $CI->db->select('versions.name as version_name, clients.name as client_name');

        $CI->db->order_by(static::class_table_name() . '.ts', 'DESC');

        return parent::all_permitted();
    }
}
