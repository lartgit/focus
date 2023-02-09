<div class="row">
<h3> Editar y validar codigo Python </h3>

    <div class="row">

        <div class="col-md-4" id="msg">
        </div>
        <!-- End row -->
    </div>

<form action="">
	
	<textarea name="txt" id="txt" cols="80" rows="40">
		<?=$basic_template_data ?>
	</textarea>
	<button class="btn btn-default" type="button" id="btn_send">Validar</button>
	<button class="btn btn-primary" type="button" data-toggle="modal" data-target="#myModal">Guardar</button>
</form>

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
			// dataType: 'default: Intelligent Guess (Other values: xml, json, script, or html)',
			data: {prm1: dt},
		})
		.done(function(res) {
            var msg_suc = '<div class="succes-string alert alert-success"><button type="button" class="close" data-dismiss="alert">&times;</button>Python Valido</div>';
			var msg_err = '<div class="error-string alert alert-danger"><button type="button" class="close" data-dismiss="alert">&times;</button>'+res+'</div>';
			if (res == 'true') {
				$("#msg").html(msg_suc);
			}else{
				$("#msg").html(msg_err);
			}
			console.log("success");
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
		$.ajax({
			url: url_save_python_file,
			type: 'POST',
			// dataType: 'text',
			// dataType: 'default: Intelligent Guess (Other values: xml, json, script, or html)',
			data: {prm1: dt,fx_id:fx_id  },
		})
		.done(function(res) {
			console.log(res)
			if (res == 'true') {
				location.href = "<?=$url_functions ?>";
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
		
	});	
});	

</script>
