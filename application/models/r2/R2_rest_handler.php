<?php

/**
 * Description of R2_Rest_Handler
 *
 * @author ABayerl
 * @abstract   Model para Manejo de Acciones de REST
 * @package    r2_core
 *
 */
class R2_Rest_Handler extends CI_Model {

    /*
     * Funcion generica para manejar pedidos por REST
     * La funcion acepta un objeto que es lo que se pasa al pedido rest.
     * Minimamente tiene: session_id, query_entity (===$this) y query_method.
     * En query_method esta la funcion de este metodo que se va a ejecutar.
     * Adicionalemte se deberian pasar los parametros de la funcion a ejecutar.
     */
    public static function rest_query($user, $query_object, &$error_string)
    {
        //Parseo el pedido
        //a que modelo voy a buscar los datos
        if (!isset($query_object->query_entity) || empty($query_object->query_entity)) {
            $error_string = 'invalid_request';
            return FALSE;
        }

        //Existe la clase?
        if(!class_exists($query_object->query_entity)) {
            $error_string = 'class_does_not_exist';
            return FALSE;
        }

        //Es el modelo queryable?
        $entity_class = $query_object->query_entity;
        if (!isset($entity_class::$_rest_queryable) || !$entity_class::$_rest_queryable) {
            $error_string = 'entity_not_queryable';
            return FALSE;
        }

        $query_entity = $query_object->query_entity;
        if (!isset($query_object->query_method) || empty($query_object->query_method))
            $query_method = "index";
        else
            $query_method = $query_object->query_method;

        //Existe el metodo dentro del modelo?
        if (!method_exists($query_entity, $query_method)) {
            $error_string = 'method_not_implemented';
            return FALSE;
        }

        //Llamamos al modelo de seguridad, para verificar si el usuario tiene ese acceso al modelo
        if (!R2_Security_Model::can_access($user, $entity_class, $query_method)) {
            $error_string = 'access_forbidden';
            return FALSE;
        }

        $manager = $query_method . "_manager";
        if (!method_exists('R2_Rest_Handler', $manager)) {
            $error_string = 'method_not_implemented';
            return FALSE;
        }

        return static::$manager($query_entity, $query_method, $query_object, $error_string);
    }

    private static function index_manager($query_entity, $query_method, $query_object, &$error_string)
    {
        $limit = (!isset($query_object->limit) || empty($query_object->limit)) ? 100 : $query_object->limit;
        $offset = (!isset($query_object->offset) || empty($query_object->offset)) ? 0 : $query_object->offset;

        return $query_entity::$query_method($offset, $limit);
    }

    private static function find_manager($query_entity, $query_method, $query_object, &$error_string)
    {
        if (!isset($query_object->entity_id) || empty($query_object->entity_id)) {
            $error_string = 'invalid_request';
            return FALSE;
        }
        $result = $query_entity::$query_method($query_object->entity_id);

        if (!$result) {
            $error_string = 'entity_not_found';
            return FALSE;
        }

        return $result;
    }

}
