<div class="row">
    <h3><?= lang($managed_class::class_plural_name()) ?></h3>

    <div class="row">

        <div class="col-md-6">
            <br>
            <?php if ($url_back) : ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
            &nbsp;
            <?php if ($user_can_add) : ?>
                <a class="btn btn-default btn-sm" href="<?= $url_new ?>">
                    <span class="glyphicon glyphicon-plus"></span> <?= lang('Agregar') ?>
                </a>
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)) : foreach ($errors as $error) : ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
            <?php endforeach;
            endif; ?>
            <div id="errors"></div>

            <?php if (isset($success)) : foreach ($success as $message) : ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($message) ?>
                    </div>
                    <br />
            <?php endforeach;
            endif; ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <div class="row">
        <div class="col-md-11">
            <table id="data-table" class="table table-striped table-bordered table-hover table-responsive table-condensed">
                <thead>
                    <tr class="info">
                        <?php if ($controller->is_developing_mode()) : ?>
                            <th>Id</th>
                        <?php endif; ?>
                        <th style="width:20%;">Descripcion</th>
                        <th>Nombre</th>
                        <th>Escena</th>
                        <th>Fecha Inicio Proceso</th>
                        <th>Fecha Fin Proceso</th>
                        <?php if ($user_can_delete) : ?>
                            <th>Borrar</th>
                        <?php endif; ?>
                        <?php if ($managed_class::class_ts_column()) : ?>
                            <th>Fecha de Alta</th>
                        <?php endif; ?>

                        <?php if ($managed_class::class_created_at_column()) : ?>
                            <th>??ltima Modificaci??n</th>
                        <?php endif; ?>

                    </tr>
                </thead>

                <tbody>
                    <?php foreach ($instances as $instance) : ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()) : ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?>
                            <td title="<?= $instance->description ?>">
                                <?= lang($instance->description) ?>
                            </td>
                            <td>
                                <?= $instance->name ?>
                            </td>
                            <td>
                                <?= $instance->pixel_set_name() ?>
                            </td>
                            <td style="padding-left: 20px; text-align: center;">
                                <?= $instance->start_process_at ?>
                            </td>
                            <td style="padding-left: 20px; text-align: center;">
                                <?= $instance->end_process_at ?>
                            </td>
                            <?php if ($user_can_delete) : ?>
                                <td>
                                    <a href="<?= $url_delete . '/' . $instance->id() ?>"><span class="glyphicon glyphicon-remove red"></span> </a>
                                </td>
                            <?php endif; ?>

                            <?php if ($managed_class::class_created_at_column()) : ?>
                                <td><?= $instance->created_at() ?></td>
                            <?php endif; ?>

                            <?php if ($managed_class::class_ts_column()) : ?>
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