<?php

/**
 * Description of R2_Security_Model
 *
 * @author ABayerl
 * @abstract   Model para manejo de la seguridad
 * @package    r2_core
 *
 */
class R2_Security_Model extends CI_Model {
    /*
     * Este modelo serviria para poder restringir accesos a distintas partes del sistema solo a usuarios. Y restringe los datos que pueden obtener.
     */

    /*
     * Funcion que acepta un usuario, un modelo y un metodo y decide si el usuario puede ejecutarlo.
     * La implementacion por ahora devuelve siempre TRUE, la idea es que a futuro se pueda restringir accesos.
     */
    public static function can_access($user, $entity_class, $query_method) {
        return TRUE;
    }
}
