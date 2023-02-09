<div class="row">
    <div class="row">
    	<div class="col-md-12">
	        <div class="col-md-4"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
	        <div class="col-md-7">
	        	<br/>
	            <div class="alert alert-info">
	                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_archivos_raster') ?>
	            </div>
	        </div>
        </div>
    </div>
    <div class="row">
        <div class="col-md-6">
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
                <a class="btn btn-default btn-sm" href="<?= $url_new_massive ?>">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Importacíon Masiva') ?>
                </a>
            <?php endif; ?>
            <a class="btn btn-default btn-sm" id="select_all" href="">
                <span class="glyphicon glyphicon-screenshot"></span> <?= lang('Seleccionar Todos') ?>
            </a>
            <a class="btn btn-default btn-sm" id="delete_selected" href="">
                <span class="glyphicon glyphicon-trash"></span> <?= lang('Borrar Seleccionados') ?>
            </a>
        </div>

        <div class="col-md-4">
            <?php if (isset($errors)): foreach ($errors as $error): ?>
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
            <?php endforeach; endif; ?>
        </div>
    </div>
    <br>
    <div class="row">
        <div class="col-md-12">
            <table id="data-table2" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th>Grupo</th>
                        <th>Path</th>
                        <th>Nombre</th>
                        <th>Tiempo</th>
                        <th>Status</th>
                        <th>Log</th>
                        <th>Carga</th>
                        <th>Cantidad</th>
                        <th>Eliminar</th>
                        <th>Seleccionar</th>
                    </tr>
                </thead>

                <tbody>
                    <?php foreach ($instances as $instance): ?>
                    <tr>
                        <?php if ($controller->is_developing_mode()): ?>
                            <td><?= $instance->id ?></td>
                        <?php endif; ?>
                        <td><?= $instance->image_type ?></td>
                        <td><?= $instance->path ?></td>
                        <td><?= $instance->name ?></td>
                        <th><?= $instance->time ?></th>
                        <td><?= $instance->status ?></td>
                        <td><a href="<?= $url_show_import_log . '/' . $instance->id() ?>"><?=lang('show_logs') ?></a></td>
                        <td><?= $instance->created_at ?></td>
                        <td><?= $instance->quantity ?></td>
                        <td><a href="<?= $url_delete_process . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span></a></td>
                        <td><input name="borrar" type="checkbox" value="<?= $instance->id() ?>"></td>
                    </tr>
                    <?php endforeach; ?>
                </tbody>

                <tfoot>
                </tfoot>
            </table>
        </div>
    </div>
</div>
<script type="text/javascript">
    $(function() {
		$('#data-table2').DataTable({
            "paging": false,
			"order": [[5, 'desc']]
        });

        $('#select_all').click(function(e) {
        	e.preventDefault();

        	$('[name="borrar"]').attr('checked', 'checked');
        });

        $('#delete_selected').click(function(e) {
        	e.preventDefault();

			var ids = $('[name="borrar"]:checked').toArray().map((x) => x.value);
			if(!ids.length) return;

			$.ajax({
				"url": "<?=$url_delete_process?>",
				"method": "POST",
				"data": {ids},
				"dataType": "json",
				"complete": function(res) {
					location.reload();
				}
			})
        });
    })
</script>