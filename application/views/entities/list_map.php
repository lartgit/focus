<div class="row">
    <br>
    <div class="row">
        <div class="col-md-6"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_mapa_de_regiones') ?>
            </div>
        </div>
    </div>

    <div class="row">

        <div class="col-md-6">
            <br>
            <?php if ($url_back): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
            &nbsp;
            <?php if ($user_can_add): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_new ?>">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Agregar') ?>
                </a>
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
                <?php
                endforeach;
            endif;
            ?>
            <div id="errors"></div>

<?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
        <?= lang($message) ?>
                    </div>
                    <br />
                <?php
                endforeach;
            endif;
            ?>
        </div>

    </div>
</div>
<br>
<div class="row">
    <div class="col-md-12">
        <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
            <thead>
                <tr class="info">
                    <?php if ($controller->is_developing_mode()): ?>
                        <th>Id</th>
<?php endif; ?>
                    <th>Nombre</th>

                    <th>Cant. Regiones</th>

                    <th>Descargar</th>

                    <th>Parametros</th>
                    <th>Estado</th>

                    <?php if ($user_can_edit): ?>
                        <th>Ver</th>
                    <?php endif; ?>

                    <?php if ($user_can_delete): ?>
                        <th>Borrar</th>
                    <?php endif; ?>


                    <?php if ($managed_class::class_ts_column()): ?>
                        <th>Fecha de Alta</th>
                    <?php endif; ?>

                    <?php if ($managed_class::class_created_at_column()): ?>
                        <th>Última Modificación</th>
<?php endif; ?>

                </tr>
            </thead>

            <tbody>

                    <?php foreach ($instances as $instance): ?>
                    <tr>
                        <?php if ($controller->is_developing_mode()): ?>
                            <td><?= $instance->id ?></td>
    <?php endif; ?>
                        <td><?= $instance->name ?></td>
                        <td><a href="#"><?= $instance->get_regions_quantity() ?></a></td>
                        <td><a  data-map-id="<?= $instance->id ?>" class="btn-sel" href="#"><?= lang('descargar') ?></a></td>
                        <td><a href="<?= $url_parameters ?>?map_id=<?= $instance->id ?>"><?= lang('parametros') ?></a></td>
                        <td><?= $instance->get_last_process_status() ?></td>
    <?php if ($user_can_edit): ?>
                            <td>
                                <a href="<?= $url_show . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-eye-open"></span> </a>
                            </td>                     
                        <?php endif; ?>

    <?php if ($user_can_delete): ?>
                            <td>
                                <a href="<?= $url_delete . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span> </a>
                            </td>
                        <?php endif; ?>

                        <?php if ($managed_class::class_created_at_column()): ?>
                            <td><?= $instance->created_at() ?></td>
                        <?php endif; ?>

                        <?php if ($managed_class::class_ts_column()): ?>
                            <td><?= $instance->ts ?></td>
                    <?php endif; ?>

                    </tr>
<?php endforeach; ?>
            </tbody>

            <tfoot>
            </tfoot>
        </table>
    </div>
</div>
<!-- Medium Modal -->
<div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?= lang('Seleccionar Directorio') ?></h4>
            </div>
            <div class="modal-body">
                <div class="panel list-group" id="list_data">
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal"><?= lang('Close') ?></button>
                <button type="button" class="btn btn-primary" id="sel_folder"><?= lang('Seleccionar') ?></button>
            </div>
        </div>
    </div>
    <!-- end Modal -->
</div>
<script>
    /*Implementacion de Ajaz*/
    var tag_i_fi = '<i class="fa fa-file-text"></i> ';
    var tag_i_fo = '<i class="fa fa-folder"></i> ';
    var current_dir = "/";
    var map_id = '';
    $(function () {
        // $('.btn-sel').click(function(){
        // 	map_id = $(this).attr('data-map-id');
        // 	dir_nav();
        // });

        $('.btn-sel').click(function (e) {
            map_id = $(this).attr('data-map-id');
            dir_nav(e);
        });

        $('#sel_folder').click(set_path);
    });

    function dir_nav(e) {
        e.preventDefault();

        $("#modal").modal();

        var ajax_read_dir = '<?= $url_ajax_read_dir ?>';


        var row_val = $(this).attr('data-name');
        if (typeof (row_val) === 'undefined') {
            row_val = '';
        }

        if (this.id != 'btn-sel') {
            if (row_val == 'back') {
                new_current_dir = current_dir.split('/');
                new_current_dir.pop();
                new_current_dir.pop();
                current_dir = new_current_dir.join('/') + '/';
            } else {
                current_dir = current_dir + row_val + '/';
            }
        }

        $.ajax({
            url: ajax_read_dir,
            data: {folder: current_dir, map_id: map_id},
            type: "POST",
            dataType: "json",
            beforeSend: function () {
                // $("#square").html('Cargando');
            },
            error: function (res) {
                // $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function (res) {
                $('#list_data').html('');
                $('#list_data').append('<a class="list-group-item dir" href="#" data-name="back">..</a>');
                for (index = 0; index < res.length; ++index) {
                    if (res[index].type == 'dir') {
                        $('#list_data').append('<a class="list-group-item dir" href="#" data-name="' + res[index].name + '">' + tag_i_fo + res[index].name + '</a>');
                    }
                }
                $('a.dir').click(dir_nav);
            }
        });
    }


    function set_path(e) {
        e.preventDefault();

        var ajax_dt_to_shp = '<?= $url_map_to_shp ?>';

        $.ajax({
            url: ajax_dt_to_shp,
            data: {folder: current_dir, map_id: map_id},
            type: "POST",
            dataType: "json",
            beforeSend: function () {
                // $("#square").html('Cargando');
            },
            error: function (res) {

                // $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function (res) {
                //  console.log(res);
                if (res == '0') {
                    // console.log("entra aca");
                    $('#modal').modal('hide');
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-success"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Archivo Creado con Exito') ?></div>';
                } else {
                    // console.log("entra aca");
                    $('#modal').modal('hide');
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-danger"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Ocurrio un error al escribir el archivo') ?></div>';
                }
            }
        });
    }
</script>    