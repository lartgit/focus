<div class="row">
    <h3>
        <?= lang('Importacion_Masiva_de_Archivos_Raster') ?>
    </h3>

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


    <!-- Medium Modal Select Dir-->
    <div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal">
        <div class="modal-dialog modal-md">
            <div class="modal-content">
                <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal">&times;</button>
                    <h4 class="modal-title"><?= lang('Seleccionar Archivo') ?></h4>
                </div>
                <div class="modal-body">
                    <div class="row">
                        <div class="col-md-6">
                            <input disabled="disabled" class="form-control" id="current_dir" value="">
                        </div>
                        <div class="col-md-6">
                            <!--<button type="button" class="btn btn-primary col-md-12" data-toggle="modal" data-target="#modal_check" id="sel_dir"><?= lang('Seleccionar Carpeta') ?></button> -->
                            <button type="button" class="btn btn-primary col-md-12" id="sel_dir"><?= lang('Seleccionar Carpeta') ?></button>
                        </div>
                        <div class="col-md-12">
                            <div class="panel list-group" id="list_data"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- end Modal -->

    <div class="row">
        <div class="col-md-8">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <?= lang('Datos del Formulario') ?>
                </div>
                <div class="panel-body">
                    <form role="form" action="<?= $url_save_process_massive ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
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
                                    <input value="<?= (isset($instance->path) && !empty($instance->path) ? $instance->path : '') ?>" class="form-control" type="text" id="path" name="path" readonly>
                                    <?php if (!isset($show)) : ?>
                                        <span class="input-group-btn">
                                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#modal" id="btn-sel"><?= lang('Seleccionar') ?></button>
                                        </span>
                                    <?php endif; ?>
                                </div>
                                <?php if (isset($errors['path'])) : ?>
                                    <?= $errors['path']; ?>
                                <?php endif; ?>
                            </div>
                        </div>
                        <div class="form-group">
                            <label class="col-md-4 control-label"><?= lang('Archivos para agregar') ?></label>
                            <div class="col-md-8">
                                <div class="panel panel-default" id="files_to_load">
                                    <div class="panel-body">

                                    </div>
                                </div>
                            </div>
                        </div>
                        <br>
                        <?php if (!isset($show)) : ?>
                            <button type="submit" id="submmit_button" class="btn btn-default ">
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?>

                        <!-- Modal de checkboxes
                        <div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal_check">
                            <div class="modal-dialog modal-md">
                                <div class="modal-content">
                                    <div class="modal-header">
                                        <button type="button" class="close" data-dismiss="modal">&times;</button>
                                        <h4 class="modal-title"><?= lang('Seleccionar Archivos') ?></h4>
                                    </div>
                                    <div class="modal-body">
                                        <div class="row">
                                            <div class="col-md-6">
                                                <input disabled="disabled" class="form-control" id="current_dir_check" value="">
                                            </div>
                                            <div class="col-md-6">
                                                <button id="sel_files" class="btn btn-primary col-md-12"><?= lang('Seleccionar Archivos') ?></button>
                                            </div>
                                            <div class="col-md-12">
                                                <div class="panel list-group" id="list_data_check"></div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>-->
                        <!-- end Modal -->
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4" id="asdfa">
            <!-- error mesagge -->
            <?php if (isset($errors)) :
                foreach ($errors as $each_error) : ?>
                    <div class="alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <strong><?= lang('Error') ?>!</strong> <?= $each_error ?>
                    </div>
            <?php endforeach;
            endif; ?>
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




    <!--  -->
</div>
<style type="text/css">
    .bootstrap-select:not([class*=col-]):not([class*=form-control]):not(.input-group-btn) {
        width: 100% !important;
    }

    table.table td {
        height: 51px;
    }
</style>
<script>
    var tag_i_fi = '<i class="glyphicon glyphicon-open-file"></i> ';
    var tag_i_fo = '<i class="glyphicon glyphicon-folder-open"></i> ';
    var current_dir = "/";

    function set_path(e) {
        e.preventDefault();

        $('#path').val('');
        $('#path').val(current_dir);
        $('#modal').modal('hide');
    }

    /*function handleClick(cb) {        
        if (cb.checked){
            $('#files_to_load').append('<div id="'+cb.value+'" class="list-group-item file"><span><i class="fa fa-file-image-o"></i></span> '+ cb.value +'</div>');
        }else{
            document.getElementById(cb.value).remove();
            //$('#'+cb.value).remove();
        }
    }*/
    $(function() {

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
            $('#current_dir').val(current_dir);
            $('#current_dir_check').val(current_dir);

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

                    //cada vez que entra en una carpeta limpio la lista de archivos seleccionados
                    $('#files_to_load').html('');

                    $('#list_data').html('');
                    $('#list_data').append('<a class="list-group-item dir" href="#" data-name="back">..</a>');

                    $('#list_data_check').html('');
                    for (index = 0; index < res.length; ++index) {
                        if (res[index].type == 'dir') {
                            $('#list_data').append('<a class="list-group-item dir" href="#" data-name="' + res[index].name + '">' + tag_i_fo + res[index].name + '</a>');
                        } else {
                            //$('#list_data').append('<a class="list-group-item file" href="#" data-name="'+ res[index].name +'">' + tag_i_fi + res[index].name +'</a>');
                            $('#list_data').append('<div class="list-group-item file">' + tag_i_fi + res[index].name + '</div>');
                            //$('#list_data').append('<div class="list-group-item file"><input type="checkbox" name="check_files[]" value="'+res[index].name+'"> ' + tag_i_fi + res[index].name +'</div>');
                            //$('#list_data_check').append('<div class="list-group-item file"><input onclick="handleClick(this);" type="checkbox" name="check_files[]" value="' + res[index].name + '">' + tag_i_fi + res[index].name + '</div>');
                            $('#files_to_load').append('<div class="list-group-item file"><input type="checkbox" name="check_files[]" value="' + res[index].name + '" checked> <span><i class="fa fa-file-image-o"></i></span> ' + tag_i_fi + res[index].name + '</div>');
                        }

                    }
                    $('a.dir').click(dir_nav);
                    // $('a.file').click(set_path);
                }
            });
        }

        $('#btn-sel').click(dir_nav);

        $('#sel_dir').click(set_path);

    });
</script>



<script>
    $(document).ready(function() {
        $('[data-toggle="tooltip"]').tooltip({
            title: "Seleccione la carpeta que contiene los archivos rasters que desea importar"
        });
    });
</script>