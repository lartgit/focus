<div class="row">
    <h3>
        <?= lang($managed_class::class_plural_name()) ?>
        <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
    </h3>

    <div class="row">
        <div class="col-md-8">
            <?php if (isset($url_back)): ?>
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
                <div class="panel-body">
                    <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal">
                        <?= $form_content ?>
                        <div class="form-group" data-placement="bottom" data-toggle="tooltip">
                            <label class="col-md-4 control-label">Path</label>
                            <div class="col-md-8">
                                <div class="input-group">
                                    <input value="<?=(isset($instance->path) && !empty($instance->path) ? $instance->path : '')  ?>" class="form-control" type="text" id="path" name="path" readonly>
                                    <?php if (!isset($show)): ?>
                                        <span class="input-group-btn">
                                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md" id="btn-sel"><?=lang('Seleccionar')?></button>
                                        </span>
                                    <?php endif; ?>
                                </div>
                            </div>
                        </div>                  
                        <br>
                        <?php if (!isset($show)): ?>
                            <button type="submit" class="btn btn-default" id="submmit_button" >
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                            <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#modal-template">
                                Formato <strong>Regiones</strong>
                            </button>
                        <?php endif; ?>
                    </form>
                </div>
            </div>
        </div>
        <div class="col-md-4">
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
        <div class="col-md-4" id="asdfa">
            <?php foreach ($instance->errors() as $each): ?>
                <div class="alert alert-danger">
                   <button type="button" class="close" data-dismiss="alert">&times;</button>
                   <strong><?= lang('Error') ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
        </div>
    </div>

<!-- Modals -->
<div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?=lang('Seleccionar Archivo')?></h4>
            </div>
            <div class="modal-body">
                <div class="panel list-group" id="list_data"></div>
            </div>
        </div>
    </div>
</div>

<div class="modal fade" tabindex="-1" role="dialog" id="modal-template">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?=lang('Template Carga')?></h4>
            </div>
            <div class="modal-body">
				<div class="row">
                    <div class="col-md-12">
                        Formato SHP de entrada:
                        <ul>
                            <li>Encoding: UTF-8.</li>
                            <li>Debe tener, al menos, las siguientes columnas:
                                <ol>
                                    <li>'<b>name</b>': Nombre de la region.</li>
                                </ol>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- end Modal -->

<script>
var tag_i_fi = '<i class="fa fa-file-text"></i> ';
var tag_i_fo = '<i class="fa fa-folder"></i> ';
var current_dir = "/";

function set_path(e){
    e.preventDefault();

    var row_val = $(this).attr('data-name');
    $('#path').val('');
    $('#path').val(current_dir+row_val);
    $('#modal').modal('hide');
}

function dir_nav(e){
  e.preventDefault();


    var ajax_read_dir = '<?=$url_ajax_read_dir ?>';


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
            }else{
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
                        $('#list_data').append('<a class="list-group-item dir" href="#" data-name="'+ res[index].name +'">' + tag_i_fo + res[index].name + '</a>');
                    }else{
                        $('#list_data').append('<a class="list-group-item file" href="#" data-name="'+ res[index].name +'">' + tag_i_fi + res[index].name +'</a>');
                    }

                }
                $('a.dir').click(dir_nav);
                $('a.file').click(set_path);

            }
         });
}

$(function(){
    $('#btn-sel').click(dir_nav);
});

</script>