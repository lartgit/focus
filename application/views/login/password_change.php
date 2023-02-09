<div class="container">
    <div class="row">
        <div class="col-md-4 col-md-offset-4">
            <div style="text-align: center; margin-top: 10%">
                <img src="<?= base_url() ?>/assets/images/logo_lart_with_text.jpg" height="100">
            </div>
            <div class="login-panel panel panel-default" style="margin-top: 10%">
                <div class="panel-heading">
                    <h3 class="panel-title">Cambio de clave</h3>
                </div>
                <div class="panel-body">
                    <form role="form" action="<?= $url_psw_save ?>" method="post" id="form">
                        <fieldset>
                            <div class="form-group">
                                <input name="code" type="hidden" value="<?= $code ?>">
                                <input class="form-control" placeholder="Contraseña" name="password" type="password" autofocus>
                            </div>
                            <div class="form-group">
                                <input class="form-control" placeholder="Nueva contraseña" name="password_confirm" type="password" value="">
                            </div>
                            <div>
                                <p  style="color:black" id="msj">
                                    <?= isset($error_string) ? "<div class='error-string alert alert-danger' role='alert'>$error_string</div>" : '' ?>
                                </p>
                            </div>
                            <!-- Change this to a button or input when using this as a form -->
                            <input value="Aceptar" type="submit">
                            <!--<a href="index.html" class="btn btn-lg btn-success btn-block">Login</a>-->

                        </fieldset>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- jQuery -->
<script src="<?= base_url() ?>/assets/js/jquery.min.js"></script>

<!-- Bootstrap Core JavaScript -->
<script src="<?= base_url() ?>/assets/js/bootstrap.min.js"></script>

<!-- Metis Menu Plugin JavaScript -->
<script src="<?= base_url() ?>/assets/js/metisMenu.min.js"></script>

<!-- Custom Theme JavaScript -->
<script src="<?= base_url() ?>/assets/js/sb-admin-2.js"></script>

