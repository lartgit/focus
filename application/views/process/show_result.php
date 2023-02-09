<div class="row">
    <div class="col-lg-12">
        <h3 class="page-header"> <?= lang('Relaciones de Importación Procesadas') . '>' . $process_result->name ?></h3>
    </div>
    <!-- /.col-lg-12 -->
</div>
<div class="row">
    <div class="col-md-4">
        <?php if (isset($error_string)) : foreach ($errors as $error) : ?>
                <div class="error-string alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= $error ?>
                </div>
        <?php endforeach;
        endif; ?>
        <div id="errors"></div>

        <?php if (isset($success)) : foreach ($success as $message) : ?>
                <div class="succes-string alert alert-success">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= $message ?>
                </div>
                <br />
        <?php endforeach;
        endif; ?>
    </div>
</div>
<!-- /.row -->
<div class="row">
    <div class="col-lg-10">
        <div class="col-lg-4">
            <?php if (isset($url_results)) : ?>
                <a class="btn btn-default btn-sm" href="<?= $url_results ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>

        </div>
    </div>
</div>
<!-- /.row -->
<br>
<div class="row show-grid col-lg-10">
    <div class="col-lg-6">
        <b><?= lang("Version") ?></b>: <?= $results['info']->version_name ?>
    </div>
    <div class="col-lg-6">
        <b><?= lang("Proyecto") ?></b>: <?= $results['info']->project_name ?>
    </div>
    <div class="col-lg-6">
        <b><?= lang("Cliente") ?></b>: <?= $results['info']->client_name ?>
    </div>
    <div class="col-lg-6">
        <b><?= lang("Usuario") ?></b>: <?= $results['info']->user_name ?>
    </div>
</div>
<div class="row">
    <div class="col-lg-10">
        <div class="col-lg-8">
            <form role="form" method="post" class="form-horizontal">
                <div class="form-group">
                    <div class="col-lg-4">
                        <div class="alert alert-info">
                            <label class="control-label"><?= lang('Formato de Descarga') ?> </label>
                            <br>
                            <input id="shp_button" type="radio" name="input_file_format" value="shp"><label for="shp_button">SHP</label>
                            <input id="xls_button" type="radio" name="input_file_format" value="xls"><label for="xls_button">Excel</label>
                        </div>
                    </div>
                    <div class="col-lg-8">
                        <div class="download_xls" style="text-align: center; display:none; overflow: visible !important;">
                            <button type="submit" class="btn btn-default">
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Descargar') ?>
                            </button>
                        </div>
                        <div class="download_shp" style="text-align: center; display:none; overflow: visible !important;">
                            <label class="col-md-2 control-label">Path</label>
                            <div class="col-md-10">
                                <div class="input-group">
                                    <input value="" class="form-control" type="text" id="path" name="path" readonly>
                                    <span class="input-group-btn">
                                        <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel"><?= lang('Seleccionar') ?></button>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>
<div class="row">
    <div class="col-lg-12">
        <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
            <thead>
                <tr class="info">
                    <th><?= lang('Campo') ?></th>
                    <th><?= lang('Lote') ?></th>
                    <th><?= lang('Cantidad de Pixeles') ?></th>
                    <th><?= lang('Cantidad de Usos') ?></th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($results['data'] as $process) : ?>
                    <tr>
                        <td><?= $process->farm_name ?></td>
                        <td><?= $process->field_name ?></td>
                        <td><?= $process->count_pixel ?></td>
                        <td><?= $process->count_uses ?></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
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
                <button type="button" class="btn btn-primary" id="sel_folder"><?= lang('Descargar') ?></button>
            </div>
        </div>
    </div>
    <!-- end Modal -->
</div>

<!-- /.row -->

<script language=JavaScript>
    $(document).ready(function() {


        $(function() {
            $('.download_xls').hide();
            $(".download_shp").hide();

        });


        $("#shp_button").change(function() {
            if (document.getElementById('shp_button').checked) {
                $('.download_shp').show('fast');
                $('.download_xls').hide('fast');
            }
        });

        $("#xls_button").change(function() {
            if (document.getElementById('xls_button').checked) {
                $('.download_xls').show('fast');
                $(".download_shp").hide('fast');
            }
        });

    });
</script>
<script type="text/javascript">
    $(".datet").datepicker({
        dateFormat: "dd-mm-yy"
    });
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
        var process_id = '<?= $process_id ?>';
        $.ajax({
            url: ajax_dt_to_shp,
            data: {
                folder: current_dir,
                process: process_id
            },
            type: "POST",
            dataType: "json",
            beforeSend: function() {
                // $("#square").html('Cargando');
            },
            error: function(res) {

                console.log('error');
                // $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function(res) {
                console.log(res);
                if (res == '0') {
                    // console.log("entra aca");
                    $('#modal').modal('hide');
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-success"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Archivo Descargado con Exito en ') ?>' + current_dir + '</div>';
                }

            },
            always: () => {
                $(this).html('<?= lang('Descargar') ?>')
            }
        });
        // $('#modal').modal('hide');
    }
</script>