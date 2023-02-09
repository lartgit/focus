<div class="row">
    <h3><?= Log_import_image::class_plural_name() ?></h3>

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
            <?php endforeach;endif; ?>
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
                        <!-- <th style="width:15%;">ID Proceso</th>   -->
                        <th style="width:70%;">Descripcion</th>  
                    </tr>
                </thead>

                <tbody>
                    
                        <?php if(isset($uses_logs)): foreach ($uses_logs as $instance): ?>
                        <tr>
                            <?php if ($controller->is_developing_mode()): ?>
                                <td><?= $instance->id ?></td>
                            <?php endif; ?> 
<!--                             <td style="text-align: center;">
                            </td>           -->
                            <td style="text-align: center;" title="">
                                <?=$instance?>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                        <?php endif; ?>
                </tbody>

                <tfoot>
                </tfoot>
            </table>
        </div>
    </div>
</div>