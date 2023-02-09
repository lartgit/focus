<div class="row">
    <h3><?= $managed_class::class_plural_name() ?></h3>

    <div class="row">

        <div class="col-md-6">
            <br>
            <?php if ($url_back): ?>
                <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
                    <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
                </a>
            <?php endif; ?>
        </div>

        <div class="col-md-4">
            <?php if (isset($error_string)): foreach ($errors as $error): ?>
                    <div class="error-string alert alert-danger">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                        <?= $error ?>
                    </div>
                <?php endforeach;
            endif; ?>
            <div id="errors"></div>

                <?php if (isset($success)): foreach ($success as $message): ?>
                    <div class="succes-string alert alert-success">
                        <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= $message ?>
                    </div>
                    <br />
            <?php endforeach;endif; ?>
        </div>
        <!-- End row -->
    </div>
    <br>
    <form method="POST" id="form" action="<?=$url_action?>">
    <div class="row">
        <div class="col-md-3">
            <label for="record_limit"><?=lang('Limite de pixeles a descargar')?>:</label>
            <input id="record_limit" name="record_limit" type="number" min="1" class="form-control" value="4800"/>
        </div>
        <div class="col-md-3">
            <label for="set_id"><?=lang('Set a descargar')?>:</label>
            <select id="set_id" name="set_id" min="1" class="form-control">
                <?php foreach($pixel_sets as $sets): ?>
                    <option value="<?=$sets->id?>"><?=$sets->name?></option>
                <?php endforeach; ?>
            </select>
        </div>
    </div><br/>
    <div class="row">
        <div class="col-md-1">
            <button type="submit" class="btn btn-default">Enviar Consulta</button>
        </div>
    </div>
    </form>
</div>
<!--<script>
    $(function(){
        $('#form').submit(function(e) {
            e.preventDefault();
            $.ajax({
                url: "<?=$url_action?>",
                data: $('#form').serialize(),
                method: "POST",
                accept: function() {
                    $("#errors")[0].innerHTML = '<div class="succes-string alert alert-success"><button type="button" class="close" data-dismiss="alert">&times;</button><?=lang('Archivo Creado con Exito')?></div>';
                    $("#errors").show();
                }
            });
        });
    });
</script>-->