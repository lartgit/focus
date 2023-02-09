<div class="row">
   <h3>
      <?= $managed_class::class_plural_name() ?>
      <?= ($instance->display_value()) ? ' > ' . $instance->display_value() : '' ?>
   </h3>

   <div class="row">
      <div class="col-md-8">
         <?php if (isset($url_back)): ?>
            <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
               <span class="glyphicon glyphicon-arrow-left"></span> <?= lang('Volver') ?>
            </a>
         <?php endif; ?>

      </div>
      <div class="col-md-4">
       
      </div>
   </div>
   <br>

   <div class="row">
      <div class="col-md-8">
         <div class="panel panel-default">
            <div class="panel-body">
               <form role="form" action="<?= $url_action ?>" method="post" class="form-horizontal">
                  <?= $form_content ?>
                  <br>
                  <?php if (isset($show)): ?>
                     <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                        <span class="glyphicon glyphicon-pencil"></span> <?= lang('Editar') ?>
                     </a>
                  <?php else: ?>
                     <button type="submit" class="btn btn-default" value="save" id="submmit_button" >
                        <span class="glyphicon glyphicon-save"></span> <?= lang('Grabar') ?>
                     </button>
                     
                     <a class="btn btn-default btn-md" href="<?= $url_import ?>">
                        <span class="glyphicon glyphicon-import"></span> <?= lang('Importar desde Archivo') ?>
                     </a>
                  <?php endif; ?>
               </form>
            </div>
         </div>
      </div>
      <div class="col-md-4" id="asdfa">
        <?php foreach ($instance->errors() as $each): ?>
            <div class="alert alert-danger">
               <button type="button" class="close" data-dismiss="alert">&times;</button>
               <strong><?= lang('Error') ?>!</strong> <?= $each ?>
            </div>
        <?php endforeach; ?>
        <?php if (isset($error_string)): foreach ($errors as $error): ?>
            <div class="error-string alert alert-danger">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= $error ?>
            </div>
        <?php endforeach; endif; ?>
        <div id="errors"></div>

        <?php if (isset($success)): foreach ($success as $message): ?>
            <div class="succes-string alert alert-success">
                <button type="button" class="close" data-dismiss="alert">&times;</button>
                <?= $message ?>
            </div>
            <br />
        <?php endforeach; endif; ?>
      </div>
   </div>

</div>
