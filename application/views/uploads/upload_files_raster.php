<div class="row">
    <br>
    <div class="row">
        <div class="col-md-6">
            <h3><?= lang($instance::class_plural_name()) ?></h3>
        </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('La fecha del Raster es prioritaria.') ?>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-md-8">
            <?php if (isset($url_back)) : ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>

        </div>
    </div>
    <br>

    <div class="row">
        <div class="col-md-8">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <?= lang('Datos del Formulario') ?>
                </div>
                <div class="panel-body">
                    <form role="form" action="<?= $url_save_process ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
                        <input type="hidden" name="id" value="">
                        <div class="form-group"><label for="image_type_id" class="col-md-4 control-label">Tipo de Imagen</label>
                            <div class="col-md-8"><select name="image_type_id" class="form-control">
                                    <?php foreach ($imagen_types as $instance2) : ?>
                                        <option value="<?= $instance2->id ?>" <?= $instance->image_type_id == $instance2->id ? "selected" : "" ?>><?= $instance2->name ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>
                        <div class="form-group"><label for="pixel_set_id" class="col-md-4 control-label">Escena</label>
                            <div class="col-md-8"><select name="pixel_set_id" class="form-control">
                                    <option value="">Autodetectar</option>
                                    <?php foreach ($sets as $instance2) : ?>
                                        <option value="<?= $instance2->id ?>" <?= $instance->pixel_set_id == $instance2->id ? "selected" : "" ?>><?= $instance2->name ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                        </div>

                        <div class="form-group" data-placement="bottom" data-toggle="tooltip">
                            <label class="col-md-4 control-label">Path</label>
                            <div class="col-md-8">
                                <div class="input-group">
                                    <input value="<?= (isset($instance->path) && !empty($instance->path) ? $instance->path : '')  ?>" class="form-control" type="text" id="path" name="path" readonly>
                                    <?php if (!isset($show)) : ?>
                                        <span class="input-group-btn">
                                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel"><?= lang('Seleccionar') ?></button>
                                        </span>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>
                        <?php if (!isset($show)) : ?>
                            <button type="submit" id="submmit_button" class="btn btn-default ">
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4" id="asdfa">
            <!-- error mesagge -->
            <?php foreach ($instance->errors() as $each) : ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong><?= lang('Error') ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
            <!-- success mesagge -->
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

    <!--  -->
</div>
<script type="text/javascript">
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

    function set_path(e) {
        e.preventDefault();

        var row_val = $(this).attr('data-name');
        $('#path').val('');
        $('#path').val(current_dir + row_val);
        $('#modal').modal('hide');
    }
</script>
<script>
    $(document).ready(function() {
        $('[data-toggle="tooltip"]').tooltip({
            title: "Seleccione el archivo .hdf con los pixeles a procesar"
        });
    });
</script>