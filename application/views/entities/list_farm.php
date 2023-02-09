<div class="row">
    <h3><?= lang($managed_class::class_plural_name()) ?></h3>

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
            <br>
            <p style="margin-left:8px;" class="label label-info">Filtrando registros para optimizar la renderizaci&oacute;n </p>
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
        <!-- Filtro para la cantidad de registros -->
    <div class="row">
        <div class="col-md-8">
            <br>
            <form method="POST" action="<?= $this->url_farms ?>">
                <div class="col-md-3">
                    <label type="text" for="limit_rows"><?= lang('Ver') ?>:</label>
                    <select class="form-control multi-select" id="limit_rows" name="limit_rows" data-toggle="tooltip-farm">
                        <option value="200"  <?=($filter_limit == 200)?"selected='selected'":""?>> 200</option>
                        <option value="500" <?=($filter_limit == 500)?"selected='selected'":""?>>500</option>
                        <option  <?=($filter_limit != 200 &&  $filter_limit != 500)?"selected='selected'":""?>> Todos</option>
                    </select>
                </div>
                <div class="col-md-2" style="margin-top:24px !important;">
                    <button type="submit" class="btn btn-default" ><?= lang('Filtrar') ?></button>
                </div>
            </form>
        </div>
    </div>
    <br>
    <!-- final del filtro -->
    <br>
    <div class="row">
        <div class="col-md-12">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                     
			   <th>Nombre</th>
                        <th>Version</th>
                        <th>Cliente</th>
                        
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

                            <td style="padding-left: 20px;
                                text-align: center; 
                        <?php echo (!$instance->is_active()) ? 'text-decoration: line-through;' : '' ?>
                                "
                                >
                                <a href="<?= $url_show . '/' . $instance->id() ?>">
                        <?= $instance->display_value() ?>
                                </a>

                            </td>

				<td>
                        <?= $instance->client_name ?>
</td>				
<td>                        <?= $instance->version_name ?>
</td>

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