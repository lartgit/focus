<div class="row">
    <br>
    <div class="row">
        <div class="col-md-5"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_regiones') ?>
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
    <div class="row">
        <div class="col-md-8">
            <form method="POST" action="<?= $url_action ?>">
                <div class="col-md-8">
                    <label type="text" for="date"><?= lang('Campos') ?>:</label>
                    <select class="form-control multi-select" id="map_id" name="map_id[]" multiple="multiple" data-toggle="tooltip-farm">
                        <?php foreach ($maps as $row): ?>
                        <option value="<?=$row->id?>"><?=$row->name?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-2" style="margin-top:24px !important;">
                    <button type="submit" class="btn btn-default" ><?= lang('Filtrar') ?></button>
                </div>
            </form>
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
                        
                        <?php if ($user_can_edit): ?>
                            <th>Editar</th>
                        <?php endif; ?>
        
                        <?php if ($user_can_delete): ?>
                            <th>Borrar</th>
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
							<td> <?=$instance->name ?></td>
                            <?php if ($user_can_edit): ?>
                                <td>
                                    <a href="<?= $url_edit . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-pencil"></span> </a>
                                </td>                     
                            <?php endif; ?>
                            
                            <?php if ($user_can_delete): ?>
                                <td>
                                    <a href="<?= $url_delete . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span> </a>
                                </td>
                            <?php endif; ?>
                            
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