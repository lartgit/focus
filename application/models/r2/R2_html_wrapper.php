<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description:
 *    Clase que permite crear forms a partir una clase que
 *    herede de MS_DbObject.
 *
 * @author NArias
 * @package MSoft
 */
class R2_Html_Wrapper extends CI_Model {

    protected $wrappedClass;
    protected $wrappedObject;
    protected $html;
    protected $pk_column;
    protected $display_column;
    public $url_class_edit;
    public $url_save_edition;
    public $html_entity_table_class = '_std_table';
    public $html_entity_form_class = 'admin-form';

    public function __construct($objectClass = NULL, MS_DbObject $aDBObject = NULL, $url_class_edit = NULL)
    {
        parent::__construct();

        // Validaciones
        if (!$objectClass)
            throw new Exception("No se ha especificado una clase.");

        if (!class_exists($objectClass))
            throw new Exception("La clase $objectClass no existe.");

        // Seteado
        $this->wrappedClass = $objectClass;
        $this->wrappedObject = $aDBObject;
        $this->url_class_edit = $url_class_edit;

        // Obtención de las columnas
        $this->pk_column = $objectClass::class_primary_key();
        $this->display_column = $objectClass::class_display_column();
    }

    // -----------------------------------------------------------------------
    // --------------------------  Public Functions  -------------------------
    // -----------------------------------------------------------------------
    public function print_class_edit_table()
    {
        $class = $this->wrappedClass;

        $instances = $class::all();

        $html = "<table class='$this->html_entity_table_class'>";
        $html.= "<thead><tr><th>$this->display_column";
        $html.= "</th><th>Edit</th></tr>";
        $html.= "</thead>";
        $html.= "<tbody>";

        foreach ($instances as $each) {
            $html.= '<tr><td style="width:200px">' . $each->display_value() . '</td>';
            $html.= '<td>';
            $html.= '<a href="' . $this->url_class_edit . '/' . $this->wrappedClass . '/' . $each->primary_key_value() . '">';
            $html.= '<img src="' . site_url('/images/msimages/edit_24x24.png') . '">';
            $html.= '</a></td></tr>';
        }

        $html .= "</tbody></table>";
        return $html;
    }

    public function print_edit_form()
    {
        return $this->generate_edit_form($this->wrappedObject);
    }

    private function generate_edit_form(MS_DbObject $object)
    {
        $this->load->helper('form');

        $form = '';
        $non_editable_vars = $object->non_editable_variables();
        $db_columns = $this->db->field_data($object->get_table_name());

        foreach ($db_columns as $each) {
            if (!in_array($each->name, $non_editable_vars))
                $fields[] = $each;
        }

        $formAttribs = Array('class' => $this->html_entity_form_class, 'style' => 'width:100%;');

        $form .= form_open($this->url_save_edition . '/' . $this->wrappedClass . '/' . $object->primary_key_value(), $formAttribs);
        $form .= form_fieldset('');

        $form .= "<table><tbody>";

        $form .="<tr><td>";
        $form .="<label>" . $object->get_primary_key() . ":</label>";
        $form .="</td><td>";

        $form .= form_hidden(array($object->get_primary_key() => $object->primary_key_value()));

        $data = array(
            'name' => $object->get_primary_key(),
            'id' => $object->get_primary_key(),
            'value' => $object->primary_key_value(),
            'disabled' => 1,
            'class' => 'admin-input'
        );

        $form .=form_input($data);

        foreach ($fields as $each) {
            $form .="<tr><td>";
            $form .="<label>$each->name :</label>";
            $form .="</td><td>";

            if ($each->type == 'bool') {

                // Mando un input hidden de mismo nombre que el checkbox con value false para que
                // siempre se envie.
                $data = array(
                    'name' => $each->name,
                    'id' => $each->name,
                    'style' => 'margin:10px',
                    'value' => 'TRUE',
                    'type' => 'hidden',
                    'value' => 'FALSE',
                    'checked' => 'checked'
                );

                $form .= form_checkbox($data);

                $data = array(
                    'name' => $each->name,
                    'id' => $each->name,
                    'style' => 'margin:10px',
                    'value' => 'TRUE'
                );

                $fieldname = $each->name;
                if ($object->$fieldname == 't')
                    $data['checked'] = 'checked';

                $form .= form_checkbox($data);
            } else {
                $fieldname = $each->name;
                $data = array(
                    'name' => $each->name,
                    'id' => $each->name,
                    'value' => $object->$fieldname,
                    'placeholder' => $each->name,
                    'class' => 'admin-input'
                );
                $form .=form_input($data);
            }
            $form .="</td></tr>";
        }

        $form .="</tbody>";
        $form .="</table>";

        $form .= "<br>" . form_submit('', 'Guardar');

        $form .=form_fieldset_close();

        return $form;
    }

}
