<div class="row">
    <h3><?= lang($process_class::class_plural_name()) ?></h3>

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
                <a class="btn btn-default btn-sm" href="<?= $url_new ?>1">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Agregar MINAGRI') ?>
                </a>
                <a class="btn btn-default btn-sm" href="<?= $url_new ?>2">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Agregar CREA') ?>
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
            <?php endforeach;endif; ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <div class="row">
        <div class="col-md-12">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed table_elipsis">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th style="width:20%;">Descripcion</th>  
                        <th>Fecha Inicio Proceso</th>
                        <th>Fecha Fin Proceso</th>
                        <th>Log Importaci&oacute;n</th>                          
                        <?php if ($user_can_delete): ?>
                            <th style="width:5%;">Borrar</th>
                        <?php endif; ?>
                        <th style="width:20%;">Archivo</th>
                        <th>Version</th>  
                        
                        <?php if ($managed_class::class_ts_column()): ?>
                            <th>Fecha de Alta</th>
                        <?php endif; ?>

                    </tr>
                </thead>

                <tbody>
                    
                        <?php foreach ($instances as $instance): ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()): ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?>
                            <td style="text-align: center;" title="<?=(isset($instance->description) ? $instance->description : $instance->display_value())?>">
                                        <a href="<?= $url_show_process . '/' . $instance->id() ?>">
                                <?=(isset($instance->description) ? $instance->description : $instance->display_value())?>
                                </a>

                            </td>                         
                            <td style="text-align: center;">
                                 <?= $instance->start_process_at ?>
                            </td>
                            <td style="text-align: center;">
                                 <?= $instance->end_process_at ?>
                            </td>
                            <td style="text-align: center;">
                                 <?= $instance->qt_errors ?>
                                 <a href="<?= $url_show_import_log . '/' . $instance->id() ?>"><?=lang('show_logs') ?> </a>
                            </td>                               
                            <?php if ($user_can_delete): ?>
                                <td>
                                    <a href="<?= $url_delete_process . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span> </a>
                                </td>
                            <?php endif; ?>
                            <td style="text-align: center;" title="<?= $instance->path_name() ?>">
                                 <?= $instance->path_name() ?>
                            </td>
                            <td style="" title="<?=$instance->client_name() .'/'. $instance->project_name() .'/'. $instance->version_name() ?>">
                                <?= $instance->client_name() .'/'. $instance->project_name() .'/'. $instance->version_name() ?>
                            </td>
                            <?php if ($managed_class::class_created_at_column()): ?>
                                <td><?= $instance->created_at() ?></td>
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