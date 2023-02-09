<table id="<?= ($controller->is_developing_mode()) ? 'data-table-xls5' : 'data-table-xls6' ?>" class="table table-striped table-bordered table-hover table-responsive table-condensed">
    <thead>
        <tr class="info">
            <?php if ($controller->is_developing_mode()) : ?>
                <th>Id</th>
            <?php endif; ?>
            <th>Estado</th>
            <th>Fecha</th>
            <th>Usuario</th>
            <th>Tiempo de Proceso</th>
            <th>Filtros Seleccionados</th>
            <th>Log</th>
            <th>Resultado</th>
            <th>Borrar</th>
        </tr>
    </thead>

    <tbody>
        <?php foreach ($instances as $instance) : ?>
            <tr>
                <?php if ($controller->is_developing_mode()) : ?>
                    <td><?= $instance->id ?></td>
                <?php endif; ?>
                <td style="text-align: center;">
                    <?= $instance->status ?>
                </td>
                <td style="text-align: center;">
                    <div style="display:none;"><?= $instance->created_at ?></div>
                    <?= $instance->created_at_str ?>
                </td>
                <td style="text-align: center;">
                    <?= $instance->user ?>
                </td>
                <td style="text-align: center;">
                    <?= $instance->time ?>
                </td>
                <td style="text-align: center;">
                    <?php if ($instance->filter_description) : ?>
                         <a type="button" class="show_filter" data-filter="<?= $instance->filter_description ?>"><span class="glyphicon glyphicon-info-sign red"></span></a>
                    <?php endif; ?>                       
                </td>
                <td style="text-align: center;">
                    <?php if ($instance->has_logs) : ?>
                        <a type="button" class="show_log" data-id="<?= $instance->id ?>"><span class="glyphicon glyphicon-info-sign red"></span></a>
                    <?php endif; ?>
                </td>
                <td style="text-align: center;">
                    <?php if ($instance->end_process_at && $instance->file_exists) : ?>
                        <a type="button" target="_blank" href="<?= $url_download_results . '/' . $instance->id ?>"><span class="glyphicon glyphicon-download red"></span> </a>
                    <?php endif; ?>
                </td>
                <td style="text-align: center;">
                    <a data-id="<?= $instance->id ?>" href="#" class="remove_process"><span class="glyphicon glyphicon-trash red"></span></a>
                </td>
            </tr>
        <?php endforeach; ?>
    </tbody>

    <tfoot>
    </tfoot>
</table>

<div class="modal fade" tabindex="-1" role="dialog" id="log_modal">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title">Log de proceso</h4>
            </div>
            <div class="modal-body">
                <table class="table">
                    <thead>
                        <tr>
                            <td>Ts</td>
                            <td>Tipo de log</td>
                            <td>Descripcion</td>
                        </tr>
                    </thead>
                    <tbody id="log_table_body"></tbody>
                </table>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>



<div class="modal fade" tabindex="-1" role="dialog" id="filter_modal">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title">Filters Description</h4>
            </div>
            <div class="modal-body">


                <div >
                    <p id="filter_table_body" > </p>
                </div>

            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>


<script>
    $(function() {
        $(".show_log").click(function() {
            $("#log_table_body").html("");
            get_request("<?= site_url(array("process_query_functions", "get_log")) ?>/" + $(this).data("id"))
                .then((json) => {
                    if (!json.length) return;

                    for (const row of json) {
                        $td1 = $("<td>").html(row.ts);
                        $td2 = $("<td>").html(row.log_type);
                        $td3 = $("<td>").html(row.description);
                        $tr = $("<tr>").append([$td1, $td2, $td3]);
                        $("#log_table_body").append($tr);
                    }

                    $("#log_modal").modal('show');
                })
        });

        $(".show_filter").click(function() {
            $("#filter_table_body").html("");


               $("#filter_table_body").append($(this).data("filter"));

            $("#filter_modal").modal('show');

            $(this).data("filter")

        });

    })




    $(".remove_process").click(function() {
        let id = $(this).data("id");

        if (confirm("Esta seguro que desea eliminar el proceso seleccionado?")) {
            return get_request("<?= site_url(array("process_query_functions", "remove")) ?>/" + $(this).data("id"))
                .then(function() {
                    window.location.reload();
                });
        }
    });

    function get_request(url) {
        return fetch(url)
            .then(response => {
                if (response.ok) {
                    return response.json();
                } else {
                    return response.json().then(t => {
                        throw t.Message
                    });
                }
            })
            .catch(res => {
                throw res;
            });
    }
</script>