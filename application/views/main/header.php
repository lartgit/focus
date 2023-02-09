    <head>

        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="description" content="">
        <meta name="author" content="">

        <title>Focus Administration Panel</title>

        <link href="<?= base_url() ?>/assets/css/helpers.css" rel="stylesheet">

        <link href="<?= base_url() ?>/assets/images/logo_lart_favicon.png" type="image/ico" rel="shortcut icon">

        <!-- Bootstrap Core CSS -->
        <link href="<?= base_url() ?>/assets/css/bootstrap.min.css" rel="stylesheet">

        <!-- MetisMenu CSS -->
        <link href="<?= base_url() ?>/assets/css/metisMenu.min.css" rel="stylesheet">

        <!-- Timeline CSS -->
        <link href="<?= base_url() ?>/assets/css/timeline.css" rel="stylesheet">

        <!-- Custom CSS -->
        <link href="<?= base_url() ?>/assets/css/sb-admin-2.css" rel="stylesheet">

        <!-- Custom Fonts -->
        <link href="<?= base_url() ?>/assets/css/font-awesome.min.css" rel="stylesheet" type="text/css">

        <!--- CSS DataTables Bootstrap -->
        <link type="text/css" rel="stylesheet" media="all" href="<?= base_url('/assets/data-tables-1.10.7/bootstrap/css/dataTables.bootstrap.css') ?>"> </link>
        <link type="text/css" rel="stylesheet" media="all" href="<?= base_url('/assets/data-tables-1.10.7/media/css/buttons.dataTables.min.css') ?>"> </link>
        <link type="text/css" rel="stylesheet" media="all" href="<?= base_url('/assets/css/bootstrap-multiselect.css') ?>"> </link>

        <!--- CSS & JS - jQuery-UI (Solo contiene el DatePicker) -->
        <link type="text/css" rel="stylesheet" media="all" href="<?= base_url('/assets/jquery-ui-datepicker/jquery-ui.min.css') ?>"> </link>
        <link rel="stylesheet" href="<?= base_url('/assets/css/jquery-ui.css') ?>">
        <!-- jQuery Lo cargo Aca porque sino tenemos problemas con el Form_builder y los campos Fechas-->
        <script src="<?= base_url() ?>/assets/js/jquery.min.js"></script>
        <script type="text/javascript" language="javascript" src="<?= base_url('/assets/jquery-ui-datepicker/jquery-ui.min.js') ?>"></script>

        <!-- Developing Refresher - Annoying as Hell!! --->
        <?php if ((isset($controller)) and ( $controller->is_developing_mode()) and false): ?>
            <meta content="30;url=<? current_url() ?>" http-equiv="refresh">
        <?php endif; ?>

        <!-- Focus CSS -->
        <link href="<?= base_url() ?>/assets/css/lart-focus.css" rel="stylesheet" type="text/css">

        <!-- /#wrapper -->

        <!-- Bootstrap Multiselect -->
        <script src="<?= base_url('/assets/js/bootstrap-multiselect.js') ?>"></script>
        <link rel="stylesheet" href="<?= base_url('/assets/css/bootstrap-multiselect.css') ?>">


        <!--- JS DataTables Bootstrap -->
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/data-tables-1.10.7/media/js/jquery.dataTables.js"></script>
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/data-tables-1.10.7/bootstrap/js/dataTables.bootstrap.js"></script>
        <script src="<?= base_url() ?>/assets/js/bootstrap.min.js"></script>

        <!-- Buttons -->
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/data-tables-1.10.7/media/js/dataTables.buttons.min.js"></script>
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/data-tables-1.10.7/media/js/jszip.min.js"></script>
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/data-tables-1.10.7/media/js/buttons.html5.min.js"></script>
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/js/jquery-ui.min.js"></script>
        <script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/js/bootstrap-multiselect.js"></script>

	<!-- Libreria de list  -->
	<script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/js/list.js"></script>
	<script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/js/list.pagination.min.js"></script>

		<!-- r2 js -->
		<script type="text/javascript" language="javascript" src="<?= base_url() ?>/assets/js/r2_functions.js"></script>

        <!-- FileInput -->
        <link href="<?= base_url() ?>/assets/css/fileinput.min.css" rel="stylesheet" type="text/css">
        <script type="text/javascript" src="<?=base_url()?>/assets/js/fileinput.min.js"></script>

        <!-- Metis Menu Plugin JavaScript -->
        <script src="<?= base_url() ?>/assets/js/metisMenu.min.js"></script>

        <!-- Morris Charts JavaScript -->
        <!--<script src="<?= base_url() ?>/assets/js/raphael-min.js"></script>-->
        <!--<script src="<?= base_url() ?>/assets/js/morris.min.js"></script>-->
        <!--<script src="<?= base_url() ?>/assets/js/morris-data.js"></script>-->

        <!-- Custom Theme JavaScript -->
        <script src="<?= base_url() ?>/assets/js/sb-admin-2.js"></script>

        <script type="text/javascript">
            var table;
            // $("#data-table").dataTable({
            // dom: 'Bfrtip',
            // buttons: [
            //     'excelHtml5',
            //     'csvHtml5'
            //     ]
            // });

            $(function () {                
            // $("#data-table").dataTable({
            //         "order": [[ 3, "desc" ]]
            // });

                table = $('#data-table').DataTable();
                
                // Aca ordenamos las tablas                  
                table
                    .column( ':contains(Fecha de Alta)' )
                    .order( 'desc' )
                    .draw();
            
                //para que puedas tener más de un data-table en una pantalla, lo mando en una clase, pero no pienso modificar todas las pantallas yuri zoolander 24/11/16
                var tables = $('.data-table').DataTable();
                
                // Aca ordenamos las tablas                  
                tables
                    .column( ':contains(Fecha de Alta)' )
                    .order( 'desc' )
                    .draw();

                $('.multi-select').multiselect({
                   buttonWidth: '100%',
                   includeSelectAllOption: true,
                   selectAllText: 'Seleccionar todos',
                   enableFiltering: true,
                   enableCaseInsensitiveFiltering: true,
                   filterPlaceholder: '<?=lang('Buscar...')?>',
                   nonSelectedText: '<?=lang('Todos seleccionados')?>',
                   nSelectedText: '<?=lang('seleccionados')?>',
                   allSelectedText: '<?=lang('Todos seleccionados')?>',
                   selectAllText: ' <?=lang('Seleccionar Todos')?>'
                });
            });
            // $("#date").datepicker();
        </script>

        <script language="Javascript">
            /*
             * Función para que el usuario no pueda hacer muchos click en el boton grabar/guardar y hacer muchos submits iguales
             */
            $(function () {
                $('#submmit_button').click(function () {
                    setTimeout(timeout_trigger_submit_false, 10);
                    setTimeout(timeout_trigger_submit_true, 500);
                });
                function timeout_trigger_submit_false() {
                    $('#submmit_button')[0].disabled = true;
                }
                function timeout_trigger_submit_true() {
                    $('#submmit_button')[0].disabled = false;
                }
            });
        </script>
    </head>



