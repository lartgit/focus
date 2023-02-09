<style type="text/css">
	.dataTables_wrapper {
    	overflow-x: auto;
	}
</style>
<div class="row">
	<h3> <?=Function_creator::$create_python_view_title  ?> </h3>
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
        <div class="col-md-4" id="msg_success" style="display: none;">
            <div class="succes-string alert alert-success"  id="msg_success1">
            <button type="button" class="close" id="close_s">&times;</button>
                <p id="txt_msg_success"></p>
            </div>
        </div>
    </div>
    <div class="row">
        <div class="col-md-4" id="msg_error" style="display: none;">
            <div class="error-string alert alert-danger">
            <button type="button" class="close" id="close_e">&times;</button>
                <p id="txt_msg_error"></p>
            </div>
        </div>
    </div>

<br>
<div class="row">
    <div class="col-md-6">
        <div class="panel panel-default">
            <div class="panel-heading">
                <?= lang('Datos') ?>
            </div>
            <div class="panel-body">
                <form action="" class="form-horizontal" id="form">
                    <input name="id" value="<?=(isset($instance->id)?$instance->id:'') ?>" type="hidden">
                    <div class="form-group">
                        <label for="name" class="col-md-4 control-label"><?=lang('Name') ?></label>
                        <div class="col-md-6">
                            <input name="name" value="<?=(isset($instance->name)?$instance->name:'') ?>" id="name" class="form-control" maxlength="50" required="1" type="text">
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="" class="col-md-4 control-label"></label>
                        <div class="col-md-8">
                            <button id="btn-add" type="button" class="col-md-4 btn btn-primary"><?=lang('add_column_name') ?></button>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="column_name" class="col-md-4 control-label"><?=lang('Column_Name') ?></label>
                        <div class="col-md-6" id="input_fields_wrap">
                        <?php if (!isset($column_names)): ?>
                            <input name="column_name[]" value="" id="column_name" class="form-control" maxlength="50" type="text">
                        <?php else: ?>
                            <?php $i=0;foreach ($column_names as $each): ?>
                            <div><input name="column_name[]" value="<?=$each ?>" id="column_name" class="form-control" maxlength="50" type="text">
                            <?php if ($i == 0 ): ?>
                                <br>
                            <?php else: ?>
                                <a href="#" class="remove_field">Remove</a>
                            <?php endif; ?>
                            </div>

                            <?php $i++;endforeach; ?>
                        <?php endif; ?>
                            <br>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="description" class="col-md-4 control-label"><?=lang('Description') ?></label>
                        <div class="col-md-8"><textarea name="description" cols="40" rows="10" id="description" class="form-control" maxlength="200"></textarea></div>
                    </div>
                    <div class="form-group">
                        <div class="col-md-8">
                        <button class="btn btn-default" type="button" id="btn_send">Validar</button>
                        <button class="btn btn-primary" type="button" data-toggle="modal" data-target="#myModal">Guardar</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="panel panel-default">
            <div class="panel-heading">
                <?= lang('Script Python') ?>
            </div>
            <div class="panel-body">
                    <div class="form-group">
                        <div class="col-md-12">
            <textarea name="txt" id="txt" cols="80" rows="120"><?php if (isset($basic_template_data)):echo $basic_template_data ?><?php endif;?></textarea>
                        </div>
                    </div>
            </div>
        </div>
    </div>
</div>

<!-- Modal -->
<div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title" id="myModalLabel">Guardar Cambios archivo Python</h4>
            </div>
            <div class="modal-body">
                Se reemplazará el código del archivo original con las nuevas modificaciones. Desea continuar?
            </div>
            <div class="modal-footer">
            <button type="button" class="btn btn-default" data-dismiss="modal"><?=lang('Cancelar') ?></button>
                <button type="button" class="btn btn-danger" id="btn_save"><?=lang('Continuar')?></button>
            </div>
        </div>
    </div>
</div>

<!-- <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.4/jquery.min.js"></script> -->

<script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/codeMirror/lib/codemirror.js"></script>
<link href="<?= base_url() ?>/assets/codeMirror/lib/codemirror.css" rel="stylesheet" type="text/css">
<script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/codeMirror/mode/python/python.js"></script>

<script>

var fx_id = '';
var url_get_python_file = '<?=$url_ajax_get_python_file ?>';
var url_save_python_file = '<?=$url_ajax_python_save ?>';

textA  =  document.getElementById('txt');

var myCodeMirror = CodeMirror.fromTextArea(textA, {
    lineNumbers: true,
    lint:true
  });


$(function(){

$("#close_s").click(function(e) {
    e.preventDefault();
    $("#msg_success").hide();
});

$("#close_e").click(function(e) {
    e.preventDefault();
    $("#msg_error").hide();
});


<?php if (isset($function_id) && $function_id != ''): ?>
        fx_id = '<?=$function_id ?>';
        $.ajax({
            url: url_get_python_file,
            type: 'POST',
            data: {fx_id: fx_id}
        })
        .done(function(res) {
            var value =  res;
            myCodeMirror.getDoc().setValue(value);
        })
        .fail(function() {
            console.log("error");
        })
        .always(function() {
            console.log("complete");
        });

<?php endif ?>

    var url = '<?=$url_ajax ?>';
    var dt = $("#txt").val();

    $("#btn_send").click(function(event) {
        var dt = myCodeMirror.getValue();
        $.ajax({
            url: url,
            type: 'POST',
            dataType: 'text',
            data: {prm1: dt},
        })
        .done(function(res) {
            if (res == 'true') {
                $("#txt_msg_success").html("Python Valido");
                $("#msg_success").show();
            }else{
                $("#txt_msg_error").html("Python Invalido:"+res);
                $("#msg_error").show();
            }
        })
        .fail(function() {
            console.log("error");
        })
        .always(function() {
            console.log("complete");
        });

    });

    $("#btn_save").click(function(event) {
        var dt = myCodeMirror.getValue();

        var fd = new FormData($('#form')[0]);
        fd.append('dataFx', dt);
        fd.append('fx_id', fx_id);


        if (form_validate()) {
            $.ajax({
                url: url_save_python_file,
                type: 'POST',
                data: fd,
                processData: false,
                contentType: false
            })
            .done(function(res) {
                console.log(res)
                if (res == 'true') {
                    $("#txt_msg_success").html("Archivo Guardado con exito");
                    $("#msg_success").show();
                }else{
                    $("#txt_msg_error").html("Ocurrio un error al guardar:"+res);
                    $("#msg_error").show();
                }

                $('#myModal').modal('hide');
                console.log("success");
            })
            .fail(function() {
                console.log("error");
            })
            .always(function() {
                console.log("complete");
            });
        }

    });



    function form_validate(){
        var regex = /^[a-z0-9\-\_]+$/;
        var name = $("#name").val();
        var column_name = $("input[name^=column_name");
        var cont = 0;
        if (name == "") {
            _show_msg_error("Nombre de funcion es requerido")
            return false;
        }

        if(regex.exec(name) === null){
            _show_msg_error("Nombre solo Minusculas y guión medio/bajo.")
            return false;
        }
        for (var i = 0; i < column_name.length; i++) {
            if (column_name[i].value != '' && column_name[i].value.indexOf(',') != -1 ) {
                _show_msg_error("Nombre de columna no puede contener comas(,).")
                return false;
            }

            if (column_name[i].value != '')
                    cont++;
        }

        if (cont == 0) {
            _show_msg_error("Nombre de columna es requerido")
            return false;
        }

        return true;
    }


    function _show_msg_error(msg){
        $("#txt_msg_error").html(msg);
        $("#msg_error").show();
        $('#myModal').modal('hide');
    }

    //***************************************************
    // La funcionalidad de agregar y remover inputs
    //***************************************************
    var add_button = $("#btn-add");
    var wrapper = $("#input_fields_wrap");
    $(add_button).click(function(e){
        e.preventDefault();
        $(wrapper).append('<div><input class="form-control" type="text" name="column_name[]"/><a href="#" class="remove_field">Remove</a></div>'); //add input
    });

    $(wrapper).on("click",".remove_field", function(e){ //remove input
        e.preventDefault(); $(this).parent('div').remove();
    })
    //***************************************************
    //End Add or remove inputs
    //***************************************************

});

</script>

<style>
.CodeMirror {
  border: 1px solid #eee;
  height: 480px;
}
</style>
