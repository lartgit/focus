<div class="row">
    <h3>Descarga de usos</h3>

    <div class="row">
        <div class="col-md-8">
            <form role="form" action="<?= site_url(array('fields', 'download')) ?>" method="post" class="form-horizontal" enctype="multipart/form-data">
                <div class="form-group">
                    <label for="client_id" class="col-md-4 control-label">Cliente</label>
                    <div class="col-md-8">
                        <select id="client_id" name="client_id" class="form-control">
                            <?php foreach ($clients as $row) : ?>
                                <option value="<?= $row->id ?>"><?= $row->name ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="project_id" class="col-md-4 control-label">Proyecto</label>
                    <div class="col-md-8">
                        <select id="project_id" name="project_id" class="form-control"></select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="version_id" class="col-md-4 control-label">Version</label>
                    <div class="col-md-8">
                        <select id="version_id" name="version_id" class="form-control"></select>
                    </div>
                </div>
                <button type="submit" id="submmit_button" class="btn btn-default ">
                    <span class="glyphicon glyphicon-save"></span>
                    Descargar
                </button>
            </form>
        </div>
        <div class="col-md-4">
            <div id="errors"></div>
        </div>
    </div>
</div>

<script>
    $(function() {
        $("#client_id").change(function(e) {
            e.preventDefault();
            var row_val = $(this).val();
            var projects = $('#project_id');

            if (row_val != '') {
                $.ajax({
                    url: '<?= site_url(['projects', 'clients_by_project']) ?>',
                    type: "POST",
                    data: {
                        client: row_val,
                    },
                    dataType: "json",
                    success: function(res) {
                        //cargo combo proyectos
                        projects.html("");
                        for (var i = 0; i < res['projects'].length; i++) {
                            projects.append($('<option>').text(res['projects'][i]['name']).attr('value', res['projects'][i]['id']));
                        }

                        $("#project_id").change();
                    }
                });
            }
        }).change();

        $("#project_id").change(function(e) {
            e.preventDefault();
            var row_val = $(this).val();
            var versions = $('#version_id');

            if (row_val != '') {
                $.ajax({
                    url: '<?= site_url(['projects', 'versions']) ?>',
                    type: "POST",
                    data: {
                        project_id: row_val,
                    },
                    dataType: "json",
                    success: function(res) {
                        //cargo combo proyectos
                        versions.html("");
                        for (var i = 0; i < res.length; i++) {
                            versions.append($('<option>').text(res[i]['name']).attr('value', res[i]['id']));
                        }
                    }
                });
            }
        })
    });
</script>