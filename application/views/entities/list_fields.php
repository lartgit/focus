<div class="row">
    <h3><?= lang($managed_class::class_plural_name()) ?></h3>

    <div class="row">

        <div class="col-md-6">
            <br>
            <?php if ($url_back): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
        </div>

        <div class="col-md-4" id="msg">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                <div class="error-string alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= lang($error) ?>
                </div>
            <?php endforeach; endif; ?>
            <div id="errors"></div>
            <?php if (isset($success)): foreach ($success as $message): ?>
                <div class="succes-string alert alert-success">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= lang($message) ?>
                </div>
                <br />
            <?php endforeach; endif; ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <div class="row">
        <div class="col-md-8">
            <form method="POST" action="<?= $url_action ?>">
                <div class="col-md-4">
                    <label type="text" for="date"><?= lang('Fecha') ?>:</label>
                    <input type="text"  value="<?= (isset($date) ? $date : '' ) ?>" class="form-control datet" name="date" id="date" data-toggle="tooltip-date">
                </div>
                <div class="col-md-4">
                    <label type="text" for="date"><?= lang('Campos') ?>:</label>
                    <select class="form-control multi-select" id="farm_id" name="farm_id[]" multiple="multiple" data-toggle="tooltip-farm">
                        <?php foreach ($farms as $row): ?>
                        <option value="<?=$row->id?>" <?=in_array($row->id, $farms_id)?"selected='selected'":""?>><?=$row->name?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-2" style="margin-top:24px !important;">
                    <button type="submit" class="btn btn-default" ><?= lang('Filtrar') ?></button>
                </div>
            </form>
        </div>
    </div><br/>
    <div class="row">
        <div class="col-md-4">
            <div class="col-md-4">
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel">
                    <span class="glyphicon glyphicon-export"></span> <?= lang('Descargar') ?>
                </button>
            </div>
        </div>
        <br/>
    </div>
    <br>
    <div class="row">
        <div class="col-md-10">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th>Nombre</th>
                        <th>Establecimiento</th>
                        <th>Desde</th>
                        <th>Hasta</th>
                        <?php if ($managed_class::class_ts_column()): ?>
                            <th>Fecha de Alta</th>
                        <?php endif; ?>

                        <?php if ($managed_class::class_created_at_column()): ?>
                            <th>Última Modificación</th>
                        <?php endif; ?>
                        <!--  <?php if ($user_can_edit): ?>
                                      <th>Editar</th>
                        <?php endif; ?>
                        <?php if ($user_can_delete): ?>
                                      <th>Borrar</th>
                        <?php endif; ?> -->

                    </tr>
                </thead>
                <tbody>

                        <?php foreach ($instances as $instance): ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()): ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?>

                            <td style="padding-left: 20px; text-align: center; <?php echo (!$instance->is_active()) ? 'text-decoration: line-through;' : '' ?>">
                                <?= $instance->display_value() ?>
                            </td>
                            <td>
                                <?= $instance->farm_name() ?>
                            </td>
                            <td>
                                <?= $instance->date_from ?>
                            </td>
                            <td>
                            <?= $instance->date_to ?>
                            </td>
                            <?php if ($managed_class::class_created_at_column()): ?>
                                <td><?= $instance->created_at() ?></td>
                            <?php endif; ?>

                            <?php if ($managed_class::class_ts_column()): ?>
                                <td><?= date('Y-m-d H:i:s', strtotime($instance->ts)) ?></td>
                            <?php endif; ?>
                            <!--     <?php if ($user_can_edit): ?>
                                             <td>
                                                 <a href="#"><span class="glyphicon glyphicon-pencil"></span> </a>
                                             </td>
                            <?php endif; ?>
                            <?php if ($user_can_delete): ?>
                                         <td>
                                             <a href="#"><span class="glyphicon glyphicon-remove red"></span> </a>
                                         </td>
                            <?php endif; ?>-->

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
</div>
<script type="text/javascript">
    $(".datet").datepicker({dateFormat: "dd-mm-yy"});
    $(".datet").datepicker("option", "dayNamesMin", ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sa"]);
    $(".datet").datepicker("option", "monthNames", ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]);

    /*Implementacion de Ajaz*/
    var tag_i_fi = '<i class="fa fa-file-text"></i> ';
    var tag_i_fo = '<i class="fa fa-folder"></i> ';
    var current_dir = "/";


    function dir_nav(e) {
        e.preventDefault();


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
            data: {folder: current_dir},
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

    $('#btn-sel').click(dir_nav);

    $('#sel_folder').click(set_path);

    function set_path(e) {
        e.preventDefault();

        var ajax_dt_to_shp = '<?= $url_ajax_dt_to_shp ?>';
        var date_to = $('#date').val();
        var farms = $('#farm_id').val();

        console.log(current_dir, date_to);

        $.ajax({
            url: ajax_dt_to_shp,
            data: {folder: current_dir, date: date_to, farm_id: farms},
            type: "POST",
            dataType: "json",
            beforeSend: function () {
                // $("#square").html('Cargando');
            },
            error: function (res) {

                console.log('error');
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

    $(function() {
        $('[data-toggle="tooltip-date"]').tooltip({title: "<?=lang('La fecha ingresada selecciona los lotes segun el Desde y Hasta de ese lote')?>"});
        $('[data-toggle="tooltip-farm"]').tooltip({title: "<?=lang('Puede seleccionar varios Campos. No seleccionar ninguno es equivalente a seleccionar todos')?>"});
    });
</script>
<style>
    .multiselect-container {
        max-height: 500px !important;
        overflow-y: auto !important;
        overflow-x: hidden !important;
    }    
</style>