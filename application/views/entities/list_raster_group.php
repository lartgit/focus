<div class="row">
    <br>
    <div class="row">
        <div class="col-md-4"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
        <div class="col-md-7">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_grupo_de_raster') ?>
            </div>
        </div>
    </div>
    <div class="row">

        <div class="col-md-6">
            <br>
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
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
                <?php endforeach;
            endif; ?>
            <div id="errors"></div>

                <?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= lang($message) ?>
                    </div>
                    <br />
    <?php endforeach;
endif; ?>
        </div>

    </div>
    <br>
    <div class="row">
        <div class="col-md-10">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th>Nombre</th>
                        <th><?=lang('cantidad_archivos') ?></th>
                        <th><?=lang('cantidad_layers') ?></th>
                        
                        <?php if ($user_can_edit): ?>
                            <th>Editar</th>
                        <?php endif; ?>
        
                        <?php if ($managed_class::class_ts_column()): ?>
                            <th>Fecha de Alta</th>
                        <?php endif; ?>

                        <?php if ($managed_class::class_created_at_column()): ?>
                            <th>Última Modificación</th>
                        <?php endif; ?>

                    </tr>
                </thead>

                <tbody>
                    
                        <?php foreach ($instances as $instance): ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()): ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?>
							
							<td><?= $instance->name ?></td>
							<td style="text-align: center;"><a href="<?=$url_rasters_files . '?image_type_id=' . $instance->id?>">
								<?=$instance->qt_files ?> 
								</a>
							</td>
							<td style="text-align: center;"><!-- <a href="<?=$url_layer_types . '?image_type_id=' . $instance->id?>"> -->
								<?=$instance->qt_layers ?> 
								<!-- </a> -->
							</td>
                            <?php if ($user_can_edit): ?>
                                <td>
                                    <a href="<?= $url_edit . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-pencil"></span> </a>
                                </td>                     
                            <?php endif; ?>
<!--                             
                            <?php if ($user_can_delete): ?>
                                <td>
                                    <a href="#"><span class="glyphicon glyphicon-remove red"></span> </a>
                                </td>
                            <?php endif; ?>
 -->                            
                            <?php if ($managed_class::class_created_at_column()): ?>
                                <td><?= $instance->created_at() ?></td>
                            <?php endif; ?>
                                
                            <?php if ($managed_class::class_ts_column()): ?>
                                <td><?= $instance->ts ?></td>
                            <?php endif; ?>

                        </tr>
        <?php endforeach; ?>
                </tbody>

                <tfoot>
                </tfoot>
            </table>
        </div>
    </div>
</div>