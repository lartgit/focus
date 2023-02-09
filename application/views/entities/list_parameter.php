<div class="row">
    <br>
    <div class="row">
        <div class="col-md-5"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_parametros') ?>
            </div>
        </div>
    </div>
    
    <div class="row">

        <div class="col-md-6">
            &nbsp;
            <?php if ($url_back): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($errors)): foreach ($errors as $error): ?>
                <div class="error-string alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <?= $error ?>
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
    </div>

    <div class="row">
        <form method="GET" id="form" class="form">
            <div class="col-md-1"><label for="map-select"><?=lang("Search")?></label></div>
            <div class="col-md-2">
                <input class="form-control" type="text" name="search" value="<?=isset($get_data['search'])?$get_data['search']:''?>">
            </div>
            <div class="col-md-1"><label for="map-select"><?=lang("Map")?></label></div>
            <div class="col-md-2">
                <select name="map_id" id="map-select" class="form-control">
                    <option value="-1">Todos</option>
                    <?php foreach ($maps as $value): ?>
                        <option value="<?=$value->primary_key_value()?>"><?=$value->display_value()?></option>
                    <?php endforeach; ?>
                </select>
            </div>
            <div class="col-md-1"><label for="region-select"><?=lang("region")?></label></div>
            <div class="col-md-2"><select name="region_id" id="region-select" class="form-control"></select></div>
            <div class="col-md-2"><button class="btn btn-primary col-md-12"><?=lang("Buscar")?></button></div>
        </form>
    </div>
    <hr>
    <div class="row">
        <div class="col-md-1"></div>
        <div class="col-md-2"><button class="btn btn-default col-md-12" id="btn-exportar"><?=lang("Descargar")?></button></div>
        <div class="col-md-2"><button class="btn btn-default col-md-12" data-toggle="modal" data-target=".bs-example-modal-md"><?=lang("Importar")?></button></div>
        <div class="col-md-2">
            <?php if(isset($get_data['map_id']) && isset($get_data['region_id']) && $get_data['region_id']!=-1 && $get_data['map_id']!=-1):?>
            	<a href="<?=$url_new.'?map_id='.$get_data['map_id'].'&region_id='.$get_data['region_id']?>" class="btn btn-danger col-md-12"><?=lang("Nuevo")?></a>
        	<?php endif;?>
        </div>
        <div class="col-md-2"><button class="btn btn-default col-md-12" id="select_all"><?=lang("Seleccionar Todos")?></button></div>
        <div class="col-md-2"><button class="btn btn-default col-md-12" id="delete_selected"><?=lang("Borrar Seleccionados")?></button></div>
    </div>
    <br>
    <div class="row">
        <div class="col-md-12">
            <table id="data-table2" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <th><?=lang("Prioridad")?></th>
                        <th><?=lang("Mapa")?></th>
                        <th><?=lang("Region")?></th>
                        <th><?=lang("Uso")?></th>
                        <th><?=lang("Mes")?></th>
                        <th><?=lang("Nombre")?></th>
                        <th><?=lang("Valor")?></th>
                        <th><?=lang("Ver")?></th>
                        <th><?=lang("Editar")?></th>
                        <th><?=lang("Borrar")?></th>
                        <th><?=lang("Seleccionar")?></th>
                    </tr>
                </thead>

                <tbody>
                    <?php foreach ($instances as $instance): ?>
                    <tr>
                        <td><?=$instance->priority?></td>
                        <td><?=$instance->map_name?></td>
                        <td><?=$instance->region_name?></td>
                        <td><?=($instance->use_name)?$instance->use_name:'%'?></td>
                        <td><?=($instance->month)?$instance->month:'%'?></td>
                        <td><?=$instance->parameter_type_name?></td>
                        <td><?=$instance->value?></td>
                        <td><a href="<?= $url_show . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-eye-open"></span></a></td>
                        <td><a href="<?= $url_edit . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-pencil"></span></a></td>
                        <td><a href="<?= $url_delete . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove"></span></a></td>
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

<div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" id="modal">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?=lang('Subir Archivo')?></h4>
            </div>
            <div class="modal-body">
                <form id="import_csv" enctype="multipart/form-data" action='<?=$url_import_parameters?>' method="POST">
                    <div class="row">
                        <div class="col-md-12">
                            Formato CSV de entrada:
                            <ul>
                                <li>Campos separado por ';' (punto y coma).</li>
                                <li>Con cabecera.</li>
                                <li>Debe tener, al menos, las siguientes columnas:
                                    <ol>
                                        <li>'<b>mapa</b>': Mapa del parámetro.</li>
                                        <li>'<b>region</b>': Región del parámetro.</li>
                                        <li>'<b>uso</b>': Uso asociado al parametro. Dejar vacio, '*' o '%' para todos los usos</li>
                                        <li>'<b>mes</b>': Mes asociado al parametro. Dejar vacio, '*' o '%' para todos los meses</li>
                                        <li>'<b>parametro</b>': Nombre del parametro.</li>
                                        <li>'<b>valor</b>': Valor del parametro.</li>
                                        <li>'<b>prioridad</b>': Al buscar un parametro, si coincide con varias reglas, se ordenan por prioridad descendente, y se toma el primero (por ej. 1 es menos prioritario que 2). Valor m&iacute;nimo: 1</li>
                                    </ol>
                                </li>
                            </ul>
                        </div>
                        <div class="col-md-12">
                            <input type="file" class="col-md-12" name="user_file" id="user_file">&nbsp;
                        </div>
                        <div class="col-md-12">
                            <input class="btn btn-primary col-md-12" type="submit" value="Subir">
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript">
    var map_id = <?=isset($get_data['map_id'])?$get_data['map_id']:'null'?>;
    var region_id = <?=isset($get_data['region_id'])?$get_data['region_id']:'null'?>;

    $(function() {
		$('#data-table2').DataTable({
            "paging": false,
			"order": [[5, 'desc']]
        });

        $("#user_file").fileinput({
            browseClass: "btn btn-primary btn-block",
            showPreview: false,
            showRemove: false,
            showUpload: false
        });

        $('#map-select').change(function(e) {
            e.preventDefault();

            $.ajax({
                url: '<?=$url_regions?>',
                data: { map_id: $(this).val() },
                success: function(res) {
                    $('#region-select').empty();

                    $('#region-select').append(
                        $('<option>').attr('value', -1).html('Todas')
                    );

                    for (var i = 0; i < res.length; i++) {
                        $('#region-select').append(
                            $('<option>').attr('value', res[i].id).html(res[i].name)
                        );
                    }

                    if(region_id) {
                        $('#region-select').val(region_id);
                    } else {
                        $('#region-select').val('');
                    }
                }
            })
        });

        $('#btn-exportar').click(function(e) {
            e.preventDefault();
            window.location = '<?=$url_export_parameters?>?' + $('#form').serialize();
        });

        if(map_id) {
            $('#map-select').val(map_id);
            $('#map-select').change();
        } else {
            $('#map-select').val('');
        }

        $('#select_all').click(function(e) {
        	e.preventDefault();

        	$('[name="borrar"]').attr('checked', 'checked');
        });

        $('#delete_selected').click(function(e) {
        	e.preventDefault();

			var ids = $('[name="borrar"]:checked').toArray().map((x) => x.value);
			if(!ids.length) return;

			$.ajax({
				"url": "<?=$url_delete?>",
				"method": "POST",
				"data": {ids},
				"dataType": "json",
				"complete": function(res) {
					location.reload();
				}
			})
        });

    });
</script>