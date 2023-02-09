<table id="<?= ($controller->is_developing_mode()) ? 'data-table-xls5' : 'data-table-xls6' ?>" class="table table-striped table-bordered table-hover table-responsive table-condensed">
    <thead>
        <tr class="info">
            <?php if ($controller->is_developing_mode()) : ?>
                <th>Id</th>
            <?php endif; ?>
            <th>Estado</th>
            <th>Fecha</th>
            <th>Usuario</th>
            <th>Nombre</th>
            <th>Descripcion</th>
            <th>Tiempo de Proceso</th>
            <th>Función</th>
            <th>Focus 1</th>
            <th>Log</th>
            <th>Resultado</th>
            <?php if ($user_can_delete) : ?>
                <th>Borrar</th>
            <?php endif; ?>
        </tr>
    </thead>

    <tbody>

        <?php foreach ($instances as $instance) : ?>
            <tr>
                <?php if ($controller->is_developing_mode()) : ?>
                    <td><?= $instance->id ?></td>
                <?php endif; ?>
                <td style="text-align: center;" id="status_<?= $instance->id ?>">
                    <?= $instance->status ?>
                </td>
                <td style="text-align: center;">
                    <?= $instance->ts ?>
                </td>
                <td style="text-align: center;">
                    <?= $instance->user ?>
                </td>
                <td style="text-align: center;">
                    <?= $instance->name ?>
                </td>
                <td style="text-align: center;">
                    <?= $instance->description_html ?>
                </td>
                <th style="text-align: center;" id="time_<?= $instance->id ?>">
                    <?= $instance->time ?>
                </th>
                <td style="text-align: center;">
                    <a href="<?= $url_download_function . '/' . $instance->function_id ?>"><span class="glyphicon glyphicon-download red"><?= $instance->function_name() ?></span></a>
                </td>
                <td style="text-align: center;">
                    <a href="<?= $url_show_process_focus_1 . '/' . $instance->process_result_id ?>"><?= $instance->process_result_name() ?></a>
                </td>
                <td style="text-align: center;">
                    <a href="<?= $url_show_log . '/' . $instance->id ?>"><span class="glyphicon glyphicon-download red"></span></a>
                </td>
                <td style="text-align: center;">
                    <a href="<?= $url_process_results_two . '/index?process_id=' . $instance->id ?>"><span class="glyphicon glyphicon-download red"></span> </a>
                </td>
                <?php if ($user_can_delete) : ?>
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