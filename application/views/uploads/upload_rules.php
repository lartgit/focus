<div class="row">
   <h3>
   </h3>

   <div class="row">
      <div class="col-md-12">
         <?php if (isset($url_back)): ?>
            <a class="btn btn-default btn-sm" href="<?= $url_back ?>">
               <span class="glyphicon glyphicon-arrow-left"></span> <?=lang('Volver')?>
            </a>
         <?php endif; ?>
       </div>
    </div>
    <br/>
    <div class="row">
      <div class="col-md-8">
         <div class="panel panel-default">
            <div class="panel-heading">
                <?=lang('Datos del Formulario') ?>
            </div>
            <div class="panel-body">
               <form role="form" action="<?=$url_upload ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
                                   
               <!--     <?=$form_content ?>-->
                
                <?php if (!$upload): ?>
                <div class="form-group">
                    <label class="col-md-4 control-label">Path</label>
                    <div class="col-md-8">
                        <div class="input-group">
                            <input class="form-control" type="text">
                            <span class="input-group-btn">
                                <button type="button" class="btn btn-primary" data-toggle="modal" data-target=".bs-example-modal-md">Seleccionar</button>
                            </span>
                        </div>   
                    </div>
                </div>
                <?php else: ?>
                    <input type="file" name="user_file" id="user_file">  
                    <div class="progress">
                        <div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width:80%">
                            <span class="sr-only">70% Complete</span>
                        </div>
                    </div> 
                <?php endif ?>                    
                  <br>
                  <?php if (isset($show)): ?>
                     <a class="btn btn-default btn-sm" href="<?= $url_edit . '/' . $instance->id() ?>">
                        <span class="glyphicon glyphicon-pencil"></span> <?=lang('Editar')?>
                     </a>
                  <?php else: ?>
                    <button type="submit" class="btn btn-default ">
                        <span class="glyphicon glyphicon-save"></span> <?=lang('Grabar')?>
                    </button>
                    <button type="button" class="btn btn-primary" data-toggle="modal" data-target="#modal-template">
                        Formato <strong>Reglas Expansion Temporal</strong>
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
   <br>

<!-- Modals -->
<div class="modal fade bs-example-modal-md" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel">
  <div class="modal-dialog modal-md">
    <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal">&times;</button>
          <h4 class="modal-title"><?=lang('Seleccionar Carpeta')?></h4>
            <div class="modal-body">
              <table class="table-responsive">
                <thead>
                  <tr>
                    <th>Nombre</th>
                  </tr>
                </thead>
                <tbody>                  
                    <?php if (isset($dir)): ?>
                        <?php foreach ($dir as $value): ?>
                            <tr><td><a class="link" href="#"><?=$value ?></a></td></tr>        
                        <?php endforeach ?>                        
                    <?php endif ?>                  
                </tbody>
              </table>
              <div id="result"></div>
            </div>          
        </div>      
    </div>
  </div>
</div>

<div class="modal fade" tabindex="-1" role="dialog" id="modal-template">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal">&times;</button>
                <h4 class="modal-title"><?=lang('Template Carga')?></h4>
            </div>
            <div class="modal-body">
				<div class="row">
                    <div class="col-md-12">
                        Formato Excel de entrada:
                        <ul>
							<li>Con cabecera.</li>
                            <li>Debe tener, al menos, las siguientes columnas:
                                <ol>
                                    <li><b>1ª columna</b>: Nombre de la region.</li>
                                    <li><b>2ª columna</b>: Uso declarado.</li>
                                    <li><b>3ª columna</b>: Uso concreto.</li>
                                    <li><b>4ª columna</b>: Mes declarado.</li>
                                    <li><b>5ª columna</b>: Mes desde.</li>
                                    <li><b>6ª columna</b>: Mes hasta.</li>
                                </ol>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<!-- end Modal -->

<!--  -->
</div>

<script type="text/javascript">

$('.link').click(function(e){
  e.preventDefault();

  console.log(this.innerHTML);

   var ajax_read_dir = '<?=$url_ajax_read_dir ?>';

        var row_val = this.innerHTML;

         $.ajax({
         url: ajax_read_dir+row_val,
         type: "POST",
         dataType: "json",
            beforeSend: function () {
               // $("#square").html('Cargando');
            },
            error: function (res) {
               $("#result").html("Ocurrio un error url: " + ajax_read_dir).fadeIn("slow");
            },
            success: function (res) {
               $("#result").html(res).fadeIn('slow');
            }
         }); 

});
</script>

<script type="text/javascript">

   function mostrar(){
     if (document.show.value != "1") {
 	document.form1.disabled = true;
        document.form2.disabled =false;
    }else{
 	if (document.show.value == "1") {
            document.form1.disabled = false;
            document.form2.disabled = true;
 	}
   }
 }
</script>
