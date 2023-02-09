<div class="row">
    <h3><?= lang($managed_class::class_plural_name()) ?></h3>
    <br>
    <div class="row">
        <div class="col-md-6">
            <form id="form_language" method="POST" action="<?= $url_change_language ?>">
                <div class="col-md-3"> 
                    <label type="text"><?= lang('seleccione_idioma') ?></label>
                </div>
                <div class="col-md-6">
                    <select value="" class="form-control" type="" id="current_lang" name="current_lang">
                        <?php foreach ($languages as $language): ?>
                            <option id="<?= $language ?>" value="<?= $language ?>" <?= ($language == $current_lang ? 'selected' : '') ?>><?= str_replace('_translation', '', $language) ?></option>
                        <?php endforeach; ?>
                    </select>

                </div>

            </form>
        </div>
        <br/>

    </div>
    <br>
    <div class="row">

        <div class="col-md-6">
            <br>
            <div class="col-md-6">
                <?php if ($url_back): ?>
                    <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                        <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                    </a>
                <?php endif; ?>
                &nbsp;
                <?php if ($url_translations): ?>
                    <a class="btn btn-default btn-sm" href="<?= $url_translations . $current_lang ?>">
                        <span class="glyphicon glyphicon-list"></span> <?= lang('ver_traducciones') ?>
                    </a>
                <?php endif; ?>

            </div>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($error) ?>
                    </div>
                    <?php
                endforeach;
            endif;
            ?>
            <div id="errors"></div>

            <?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= lang($message) ?>
                    </div>
                    <br />
                    <?php
                endforeach;
            endif;
            ?>
        </div>

    </div>
    <br>

    <div class="row">
        <div class="col-md-8">
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
                                text-align: center;">
                                <a href="<?= $url_show . '/' . $instance->id . '/' . $current_lang ?>">
                                    <?= $instance->current_name ?>
                                </a>

                            </td>
                            <?php if ($user_can_edit): ?>
                                <td>
                                    <a href="<?= $url_edit . '/' . $instance->id . '/' . $current_lang ?>"><span class="glyphicon glyphicon-pencil"></span> </a>
                                </td>                     
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
<script type="text/javascript">
    $(function () {
        $("#current_lang").change(function (e) {
            e.preventDefault();
            $('#form_language').submit();

        });

    });
</script>