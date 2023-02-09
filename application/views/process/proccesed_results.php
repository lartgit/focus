<div class="row">
    <div class="col-lg-12">
        <h3 class="page-header"> <?= lang('Relaciones de Importación Procesadas') ?></h3>
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
    <div class="col-md-4">
        <label for="path"><?= lang('Reimportacion de resultados para seleccion de pixeles') ?>:</label>
        <div class="input-group">
            <input value="<?= (isset($instances->path) && !empty($instances->path) ? $instances->path : '') ?>" class="form-control" type="text" id="path" name="path" readonly>
            <span class="input-group-btn">
                <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel"><?= lang('Seleccionar') ?></button>
            </span>
            <span class="input-group-btn">
                <button type="button" class="btn btn-primary" id="btn-import"><?= lang('Reimportar') ?></button>
            </span>
        </div>
    </div>
</div>
<br />
<div class="row">
    <div class="col-lg-12">
        <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
            <thead>
                <tr class="info">
                    <th><?= lang('Nombre') ?></th>
                    <th><?= lang('Cantidad de filas') ?></th>
                    <th><?= lang('Escenas') ?></th>
                    <th><?= lang('Client/Proyecto/Version') ?></th>
                    <th><?= lang('Regla de Selección de Pixeles') ?></th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($instances as $process) : ?>

                    <tr>
                        <td> <a href="<?= $url_show_process ?><?= $process->id ?>"> <?= $process->name ?> </a></td>
                        <td><?= $process->row_count ?></td>
                        <td><?= $process->imagen_type_name ?></td>
                        <td title="<?= $process->cli_name . '/' . $process->proy_name . '/' . $process->version_name ?>"><?= $process->cli_name . '/' . $process->proy_name . '/' . $process->version_name ?></td>
                        <td><?= $process->px_rule_name ?></td>
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
                <h4 class="modal-title"><?= lang('Seleccionar Archivo') ?></h4>
            </div>
            <div class="modal-body">
                <div class="panel list-group" id="list_data">
                </div>
            </div>
        </div>
    </div>
    <!-- end Modal -->
</div>

<script type="text/javascript">
    var tag_i_fi = '<i class="fa fa-file-text"></i> ';
    var tag_i_fo = '<i class="fa fa-folder"></i> ';
    var current_dir = "/";

    var ajax_read_dir = '<?= $url_ajax_read_dir ?>';
    var ajax_read_shp = '<?= $url_ajax_read_shp ?>';

    function dir_nav(e) {
        e.preventDefault();

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
            success: function(res) {
                $('#list_data').html('');
                $('#list_data').append('<a class="list-group-item dir" href="#" data-name="back">..</a>');
                for (index = 0; index < res.length; ++index) {
                    if (res[index].type == 'dir') {
                        $('#list_data').append('<a class="list-group-item dir" href="#" data-name="' + res[index].name + '">' + tag_i_fo + res[index].name + '</a>');
                    } else {
                        $('#list_data').append('<a class="list-group-item file" href="#" data-name="' + res[index].name + '">' + tag_i_fi + res[index].name + '</a>');
                    }

                }
                $('a.dir').click(dir_nav);
                $('a.file').click(set_path);

            }
        });
    }

    $('#btn-sel').click(dir_nav);

    $('#btn-import').click(function() {
        $.ajax({
            url: ajax_read_shp,
            data: {
                file: $('#path').val()
            },
            type: "POST",
            dataType: "json",
            success: function(res) {
                if (res == '0') {
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-success"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Archivo Reimportado con exito') ?></div>';
                } else {
                    $("#errors").show();
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-danger"><button type="button" class="close" data-dismiss="alert">&times;</button><?= lang('Ocurrio un error al leer el archivo') ?></div>';
                }
            }
        });
    });

    function set_path(e) {
        e.preventDefault();

        var row_val = $(this).attr('data-name');
        $('#path').val('');
        $('#path').val(current_dir + row_val);
        $('#modal').modal('hide');
    }
</script>