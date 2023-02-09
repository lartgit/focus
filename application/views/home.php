<div class="row">
   <div class="col-lg-12">
      <h1 class="page-header">Bienvenido</h1>
   </div>
   <!-- /.col-lg-12 -->
</div>
<!-- /.row -->
<div class="row">
   <div class="col-lg-4 col-md-6">
      <div class="panel panel-primary">
         <div class="panel-heading">
            <div class="row">
               <div class="col-xs-3">
                  <i class="fa fa-file fa-4x"></i>
               </div>
               <div class="col-xs-9 text-right">
                  <div class="huge"><?=$index_data['last7_ammt']->value?></div>
                  <div><?=lang('Procesos finalizados en los ultimos 7 dias')?></div>
               </div>
            </div>
         </div>
      </div>
   </div>
   <div class="col-lg-4 col-md-6">
      <div class="panel panel-primary">
         <div class="panel-heading">
            <div class="row">
               <div class="col-xs-3">
                  <i class="fa fa-file fa-4x"></i>
               </div>
               <div class="col-xs-9 text-right">
                  <div class="huge"><?=$index_data['last30_ammt']->value?></div>
                  <div><?=lang('Procesos finalizados en los ultimos 30 dias')?></div>
               </div>
            </div>
         </div>
      </div>
   </div>
   <div class="col-lg-4 col-md-6">
      <div class="panel panel-primary">
         <div class="panel-heading">
            <div class="row">
               <div class="col-xs-3">
                  <i class="fa fa-file fa-4x"></i>
               </div>
               <div class="col-xs-9 text-right">
                  <div class="huge"><?=$index_data['db_size']->total_pretty?></div>
                  <div><?=lang('Tama&ntilde;o DB')?></div>
               </div>
            </div>
         </div>
      </div>
   </div>
</div>
<!-- /.row -->
<div class="row">
   <div class="col-lg-8">
      <div class="panel panel-default">
         <div class="panel-heading">
            <i class="fa fa-bar-chart-o fa-fw"></i><?=lang('Ultimos Procesos')?>
         </div>
         <!-- /.panel-heading -->
         <div class="table-responsive">
            <table class="table table-bordered table-hover table-striped">
                <thead>
                    <tr>
                        <th><?=lang('process_class')?></th>
                        <th><?=lang('created_at')?></th>
                        <th><?=lang('start_process_at')?></th>
                        <th><?=lang('end_process_at')?></th>
                        <th><?=lang('description')?></th>
                        <th><?=lang('email')?></th>
                        <th><?=lang('procces_run')?></th>
                    </tr>
                </thead>
                <tbody>
                <?php foreach($index_data['process_table'] as $value): ?>
                    <tr>
                        <?php if($value->process_class == 'process_results'): ?>
                            <td><a href="<?=$url_results.'/show_result/'.$value->id?>"><?=lang($value->process_class)?></a></td>
                        <?php elseif($value->process_class == 'process_functions'): ?>
                            <td><a href="<?=$url_process_results_two.'/index?process_id='.$value->id?>"><?=lang($value->process_class)?></a></td>
                        <?php else: ?>
                            <td><?=lang($value->process_class)?></td>
                        <?php endif; ?>
                        <td><?=$value->created_at?></td>
                        <td><?=$value->start_process_at?></td>
                        <td><?=$value->end_process_at?></td>
                        <td><?=$value->description?></td>
                        <td><?=$value->email?></td>
                        <td><?=($value->procces_run==='t')?'True':'False'?></td>
                    </tr>
                <?php endforeach; ?>
               </tbody>
            </table>
         </div>
      </div>
      <!-- /.panel -->

      <div id=""></div>
      <!-- /.panel -->
      <!-- /.panel -->
   </div>
   <!-- /.col-lg-8 -->
   <div class="col-lg-4">
      <div class="panel panel-default">
         <div class="panel-heading">
            <i class="fa fa-object-group"></i> <?=lang('Últimas imagenes por Tipo')?>
         </div>
         <!-- /.panel-heading -->
         <div class="table-responsive">
            <table class="table table-bordered table-hover table-striped">
               <thead>
                  <tr>
                     <th><?=lang('Tipo (Pixel Size)')?></th>
                     <th><?=lang('Ultima Imagen')?></th>
                  </tr>
               </thead>
               <tbody>
                <?php foreach($index_data['images_table'] as $value): ?>
                  <tr>
                    <td><a href="<?=$url_imagen_types."/edit/".$value->id?>"><?=$value->name?> (<?=$value->pixel_size?>)</td>
                    <td><?=$value->last_image_date?$value->last_image_date:'N/A'?></td>
                  </tr>
                <?php endforeach; ?>
               </tbody>
            </table>
         </div>
         <!-- /.table-responsive -->
         <!-- /.panel-body -->
      </div>
      <!-- /.panel -->


   </div>
   <!-- /.col-lg-4 -->
</div>
<!-- /.row -->