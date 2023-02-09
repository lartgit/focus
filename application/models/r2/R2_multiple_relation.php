<?php

if (!defined('BASEPATH'))
    exit('No direct script access allowed');

/**
 * Description of MS_Multiple_Relation
 *    Clase abstracta que modela una relación de muchos a muchos.
 *
 */
abstract class R2_Multiple_Relation extends R2_DbObject {
    /* {2014-08-24} */

    // Construct
    public function __construct()
    {
        parent::__construct();
    }

    // Es obligación de las subclases redefinir el array de clases que referencia.
    public static function references_class()
    {
        throw new Exception('No se ha configurado correctamente las relaciones de: ' . get_called_class());
    }

    public static function available_to($instance)
    {
        if (!$right_column = static::references_to($instance))
            throw new Exception('No se tienen configuradas relaciones en: ' . get_called_class() . ' para: ' . get_class($instance));

        $relateds = static::all_related_to($instance);

        $relation = static::left_relation_for_right_column($right_column);

        $left_column = $relation->column;
        $left_class = $relation->class;

        $ids = Array();
        foreach ($relateds as $each) $ids[] = $each->$left_column;

        return $left_class::where_not_in($left_class::class_primary_key(), $ids);
    }

    protected static function left_relation_for_right_column($right_column)
    {
        foreach (static::references_class() as $column => $class) {
            if ($column != $right_column) {
                $relation['class'] = $class;
                $relation['column'] = $column;
                return (object) $relation;
            }
        }
        return FALSE;
    }

    protected static function references_to($instance)
    {
        return(array_search(get_class($instance), static::references_class()));
    }

    public static function delete_where_left_right($left_class, $left_id, $right_id)
    {
        foreach (static::references_class() as $key => $value) {
            if ($value == $left_class) {
                $left_column = $key;
            } else {
                $right_column = $key;
                $right_class = $value;
            }
        }

        $instances = static::where(array($left_column => $left_id, $right_column => $right_id));

        return static::delete($instances[0]->primary_key_value());
    }

    public static function new_with($left_class, $left_id, $right_id)
    {
        foreach (static::references_class() as $key => $value) {
            if ($value == $left_class) {
                $left_column = $key;
            } else {
                $right_column = $key;
                $right_class = $value;
            }
        }

        $instance = new static();
        $instance->$left_column = $left_id;
        $instance->$right_column = $right_id;

        return($instance);
    }

    /**
     * Devuelve un array de instancias de la clase a la que referencia a travez
     * de la tabla de muchos a muchos.
     */
    public static function all_related_to($instance)
    {
        $instance_class = $instance->class_name();
        $references = static::references_class();

        if (!in_array($instance_class, $references))
            throw new Exception('En ' . get_called_class() . ' no hay referencias configuradas con la clase: ' . $class . '.');

        $ciObj = & get_instance();

        $column = array_search($instance_class, $references);

        $relations = self::where(array($column => $instance->primary_key_value()));

        if (!empty($relations)) {

            // Busco la otra clase y columna que la referencia
            foreach ($references as $key => $value)
                    if ($value != $instance_class) {
                    $target_column = $key;
                    $target_class = $value;
                }

            foreach ($relations as $each_relation)
                    $ids[] = $each_relation->$target_column;

            return $target_class::find_ids($ids);
        }
        return Array();
    }

    public static function all_non_related_to($instance)
    {
        $instance_class = $instance->class_name();
        $references = static::references_class();

        if (!in_array($instance_class, $references))
            throw new Exception('En ' . get_called_class() . ' no hay referencias configuradas con la clase: ' . $class . '.');

        $ciObj = & get_instance();

        $column = array_search($instance_class, $references);

        $relations = self::where(array($column => $instance->primary_key_value()));

        //if (!empty($relations)) {
        // Busco la otra clase y columna que la referencia
        foreach ($references as $key => $value) {
            if ($value != $instance_class) {
                $target_column = $key;
                $target_class = $value;
            }
        }

        foreach ($relations as $each_relation)
                $ids[] = $each_relation->$target_column;

        if (empty($ids)) {
            $ids[] = 0;
        }

        return $target_class::find_not_ids($ids);
        //}
        return Array();
    }

}
