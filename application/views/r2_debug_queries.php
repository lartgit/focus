<div class="queries_table_container">
   <table class="queries_table">
      <thead>
         <tr>
            <th>
               Loaded view: '<?= (isset($view_name) ? $view_name : '') ?>' in in {elapsed_time} seconds
            </th>
         </tr>
         <tr>
            <th>
               <b>Queries Realizadas</b>
               <br>
               (Desactivar en el config['develping_mode'] = <b>FALSE</b>)
            </th>
         </tr>
      </thead>
      <tbody>
         <?php foreach ($queries as $each_query): ?>
            <tr>
               <td>
                  <?= ($each_query) ?>
               </td>
            </tr>
         <?php endforeach ?>

      </tbody>
   </table>
</div>

<style type="text/css">

   .queries_table th, .queries_table td{
      border: 1px solid lightgray;
   }
   .queries_table th{
      background: darkgray;
      font-weight: bold;
      text-align: center;
   }
   .queries_table td{
      padding:4px;
   }
   
   .queries_table {
      width: 100%;
   }   
   .queries_table_container{
      margin-top: 5px;
      padding: 10px;
      bottom: 0;
      position: fixed;
      right: 0;
      min-width: 900px;
      z-index: 1000;
   }



</style>
