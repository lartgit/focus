<div class="row">
    <h3>
        <?= lang($managed_class::class_plural_name()) ?>
        <?= ' > ' . str_replace('_translation', '', $current_lang) ?>
        <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
    </h3>

    <div class="row">
        <div class="col-md-8">
            <?php if (isset($url_back)): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back . '/' . $current_lang ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>

        </div>
    </div>
    <br>

    <div class="row">
        <div class="col-md-8">
            <div class="panel panel-default">
                <div class="panel-body">
                    <form role="form" action="<?= $url_action . "/" . $current_lang ?>" method="post" class="form-horizontal">
                        <input type="hidden" name="id" value="<?= $instance->id ?>">
                        <div class="form-group">
                            <label class="col-md-4 control-label">Current name</label>
                            <div class="col-md-8">
                                <input class="form-control" value="<?= $instance->current_name ?>" id="name" name="name" disabled>
                            </div>
                        </div>  
                        <div class="form-group">
                            <label class="col-md-4 control-label">Translation</label>
                            <div class="col-md-8">
                                <input class="form-control" value="<?= (($instance->$current_lang) ? $instance->$current_lang : '') ?>" id="translation" name="<?= $current_lang ?>" <?php if (isset($show)) echo 'disabled' ?>>
                            </div>
                        </div>  
                        <br>
                        <?php if (isset($show)): ?>
                            <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() . '/' . $current_lang ?>">
                                <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                            </a>
                        <?php else: ?>
                            <button type="submit" class="btn btn-default" id="submmit_button" >
                                <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                            </button>
                        <?php endif; ?>
                    </form>
                </div>
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
        <div class="col-md-4" id="asdfa">
            <?php foreach ($instance->errors() as $each): ?>
                <div class="alert alert-danger">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    <strong><?= lang('Error') ?>!</strong> <?= $each ?>
                </div>
            <?php endforeach; ?>
        </div>
    </div>

</div>

