<div class="row">
    <br>
    <div class="row">
        <div class="col-md-5"> <h3><?= lang($managed_class::class_plural_name()) ?></h3> </div>
        <div class="col-md-6">
            <div class="alert alert-info">
                <strong>Info:</strong> <?= lang('descripcion_de_pantalla_funciones') ?>
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
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Importar Nueva Función') ?>
                </a>
                <a class="btn btn-default btn-sm" href="<?= $url_new_from_basic_template ?>">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Crear Nueva Función') ?>
                </a>                
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($errors)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= $error ?>
                    </div>
                    <?php
                endforeach;
            endif;
            ?>
            <div id="errors"></div>

            <?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= $message ?>
                    </div>
                    <br />
                    <?php
                endforeach;
            endif;
            ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <div class="row">
        <div class="col-md-11">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed table_elipsis">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()): ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th>Función</th>  
                        <th>Usuario</th>  
                        <th>Fecha</th>
                        <th>Descargar</th>
                        <th>Editar</th>
                        <th>Editar Python</th>
                        <?php if ($user_can_delete): ?>
                            <th>Borrar</th>
                        <?php endif; ?>

                    </tr>
                </thead>

                <tbody>

                    <?php foreach ($instances as $instance): ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()): ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?>
                            <td style="text-align: center;">
                                <?= $instance->name ?>
                            </td>    
                            <td style="text-align: center;">
                                <?= $instance->user->name ?>
                            </td>   
                            <td style="text-align: center;">
                                <?= $instance->ts ?>
                            </td>
                            <td style="text-align: center;" title="<?= $instance->path_name() ?>">
                                <a href="<?= $url_download_function . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-download red"></span></a>
                            </td>
                            <td style="text-align: center;">
                                <a href="<?= $url_edit_function . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-edit red"></span> </a>
                            </td>
                            <td style="text-align: center;">
                                <a href="<?= $url_test_python . '?fx_id=' . $instance->id() ?>"><span class="glyphicon glyphicon-edit red"></span> </a>
                            </td>                            
                            <?php if ($user_can_delete): ?>
                                <td style="text-align: center;">
                                    <a href="<?= $url_delete_function . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span> </a>
                                </td>
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