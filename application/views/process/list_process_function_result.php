<style type="text/css">
    .dataTables_wrapper {
        overflow-x: auto;
    }
</style>
<div class="row">
    <br>
    <div class="row">
        <div class="col-md-6">
            <h3><?= lang("process_function_result_title") ?></h3>
        </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('Se muestran 200 registros.') ?>
            </div>
        </div>
    </div>

    <div class="row">

        <div class="col-md-6">
            <br>
            &nbsp;
            <?php if (isset($user_can_add) && $user_can_add) : ?>
                <a class="btn btn-default btn-sm" href="<?= $url_new ?>">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Agregar') ?>
                </a>
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)) : foreach ($errors as $error) : ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
            <?php endforeach;
            endif; ?>
            <div id="errors"></div>

            <?php if (isset($success)) : foreach ($success as $message) : ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($message) ?>
                    </div>
                    <br />
            <?php endforeach;
            endif; ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <div class="row">
        <div class="col-md-12">
            <form method="POST" action="<?= $url_action ?>" id="frm_filter">
                <div class="col-md-2">
                    <label type="text" for="version_id"><?= lang('Versiones') ?>:</label>
                    <select class="form-control multi-select2" id="version_id" name="version_id" data-toggle="tooltip-farm">
                        <?php foreach ($versions as $row) : ?>
                            <option value="<?= $row->id ?>" <?= ($version_id == $row->id) ? 'selected="selected"' : "" ?>><?= $row->name ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-2">
                    <label type="text" for="process_id"><?= lang('Procesos') ?>:</label>
                    <select class="form-control multi-select2" id="process_id" name="process_id" data-toggle="tooltip-farm">
                    </select>
                </div>
                <div class="col-md-2">
                    <label type="text" for="grouped_month"><?= lang('Agrupado por mes') ?>:</label>
                    <input type="checkbox" id="grouped_month" name="grouped[]" value="month" <?= isset($grouped) && in_array('month', $grouped) ? 'checked="checked"' : '' ?>>

                    <label type="text" for="grouped_field"><?= lang('Agrupado por lote') ?>:</label>
                    <input type="checkbox" id="grouped_field" name="grouped[]" value="field" <?= isset($grouped) && in_array('field', $grouped) ? 'checked="checked"' : '' ?>>

                    <table class="table" id="column_agregates"></table>
                </div>
                <div class="col-md-2" style="margin-top:24px !important;">
                    <button type="submit" class="btn btn-default"><?= lang('Filtrar') ?></button>
                </div>
                <?php if (isset($process_id) && $process_id != '' && !isset($error_string)) : ?>
                    <div class="col-md-2" style="margin-top:24px !important;">
                        <input type="hidden" value="<?= (isset($process_id) && $process_id != '') ? $process_id : '' ?>" id="sel_process_id">
                        <a type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel"><?= lang('Descarga SHP') ?></a>
                    </div>
                    <div class="col-md-2" style="margin-top:24px !important;">
                        <input type="hidden" value="<?= (isset($process_id) && $process_id != '') ? $process_id : '' ?>" id="sel_process_id">
                        <button id="xls_exp" type="button" class="btn btn-success"><?= lang('Descarga CSV') ?></button>
                        <a id="xls_exp1" href="#" hidden="hidden"></a>
                    </div>
                <?php endif ?>
            </form>
        </div>
    </div>
    <!-- <br> -->
    <hr>

    <?php if (isset($instances) && count($instances) > 0) : ?>
        <div class="row">
            <div class="col-md-11">
                <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                    <thead>
                        <tr class="info">
                            <?php foreach ($columns as $each) : ?>
                                <th><?= $each ?></th>
                            <?php endforeach ?>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($instances as $instance) : ?>
                            <tr>
                                <?php foreach ($columns as $col) : ?>
                                    <td>
                                        <?= $instance->$col ?>
                                    </td>
                                <?php endforeach ?>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                    <tfoot>
                    </tfoot>
                </table>
            </div>
        </div>
    <?php endif ?>

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
<!-- End div row general -->

<script type="text/javascript">
    var selected = <?= json_encode($aggregates) ?>;
    $('#grouped_month,#grouped_field').change(change_table);
    $('#process_id').change(change_table);

    var download_files_url = '<?= $url_download_files  ?>';

    var selected_process_id = '<?= $process_id ?>';

    $(function() {
        $("#xls_exp").click(function(e) {
            var url_xl = '<?= $url_dt_to_xls . '/?' ?>' + $('#frm_filter').serialize();
            console.log(url_xl);
            e.preventDefault();
            console.log(url_xl);
            location.href = url_xl;
        });

        $('.multi-select2').multiselect({
            buttonWidth: '100%',
            includeSelectAllOption: true,
            selectAllText: 'Seleccionar todos',
            enableFiltering: true,
            enableCaseInsensitiveFiltering: true,
            filterPlaceholder: '<?= lang('Buscar...') ?>',
            nonSelectedText: '<?= lang('Seleccione Uno') ?>',
            nSelectedText: '<?= lang('seleccionados') ?>',
            allSelectedText: '<?= lang('Todos seleccionados') ?>',
            selectAllText: ' <?= lang('Seleccionar Todos') ?>'
        });

        $('#version_id').change(function() {
            $.ajax({
                url: "<?= site_url(array("process_functions_results", "process_for_version")) ?>/" + $(this).val(),
                success: function(res) {
                    data = JSON.parse(res);

                    $('#process_id').html("");
                    for (var x of data) {
                        $('#process_id').append($('<option>').attr('value', x.id).html(x.name));
                    }
                    $('#process_id').val(selected_process_id);
                    $('#process_id').multiselect('rebuild');
                    $('#process_id').change();
                }
            })
        });
        $('#version_id').change();
    });

    function change_table(ev) {
        ev.preventDefault();

        if ($('#grouped_field')[0].checked && !$('#grouped_month')[0].checked) {
            $.ajax('<?= $url_get_columns ?>', {
                method: 'POST',
                data: {
                    process_id: $('#process_id').val()
                },
            }).done(function(data, textStatus, jqXHR) {
                try {
                    var obj = JSON.parse(data);

                    $('#column_agregates').html('');
                    for (var i = 0; i < obj.length; i++) {
                        var label = $('<label>').attr('for', obj[i]).html(obj[i]);
                        var hidden = $('<input type=hidden name=aggregates[' + i + '][key] value="' + obj[i] + '" class="form-control">');
                        var select = $('<select class="form-control">').attr('id', obj[i]).attr('name', 'aggregates[' + i + '][value]').html(obj[i]);
                        select.append($('<option>').html('N/A'));

                        <?php foreach (Results_two::$_aggregates as $key => $value) : ?>
                            select.append($('<option>').attr('value', '<?= $key ?>').html('<?= lang($key) ?>'));
                        <?php endforeach; ?>

                        if (selected && selected[obj[i]]) select.val(selected[obj[i]]);

                        $('#column_agregates').append($('<tr>').append($('<td>').append(label)).append($('<td>').append(select).append(hidden)));
                    }
                } catch (e) {}
            });

            $('#column_agregates').show();
        } else
            $('#column_agregates').hide();
    }
    $('#grouped_field').change();

    /*Implementacion de Ajaz*/
    var tag_i_fi = '<i class="fa fa-file-text"></i> ';
    var tag_i_fo = '<i class="fa fa-folder"></i> ';
    var current_dir = "/";

    function dir_nav(e) {
        e.preventDefault();

        var ajax_read_dir = '<?= $url_ajax_read_dir ?>';

        var row_val = $(this).attr('data-name');
        if (typeof(row_val) === 'undefined') {
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
            data: {
                folder: current_dir
            },
            type: "POST",
            dataType: "json",
            beforeSend: function() {
                // $("#square").html('Cargando');
            },
            error: function(res) {
                // $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function(res) {
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
        $(this).html('<i class="fa fa-spin fa-spinner"></i> <?= lang('Descargar') ?>')

        var ajax_dt_to_shp = '<?= $url_ajax_dt_to_shp ?>';
        //var date_to = $('#date').val();
        var prox = $('#sel_process_id').val();

        //console.log(current_dir, date_to);

        $.ajax({
            url: ajax_dt_to_shp,
            data: {
                folder: current_dir,
                process_id: prox,
                agg_data: $("#frm_filter").serialize()
            },
            type: "POST",
            dataType: "json",
            beforeSend: function() {
                // $("#square").html('Cargando');
                // Al pedo!
            },
            error: function(res) {
                console.log('error');
            },
            success: function(res) {
                //  console.log(res);
                if (res == '0') {
                    // console.log("entra aca");
                    $('#modal').modal('hide');
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-success"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Archivo Creado con Exito') ?></div>';
                    location.href = download_files_url + '?current_dir=' + encodeURI(current_dir);

                } else {
                    // console.log("entra aca");
                    $('#modal').modal('hide');
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-danger"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Ocurrio un error al escribir el archivo') ?></div>';
                }
            },
            always: () => {
                $(this).html('<?= lang('Descargar') ?>')
            }
        });
    }
</script>