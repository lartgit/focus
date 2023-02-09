<div class="navbar-header">
            <img class="navbar-brand" src="<?= base_url() ?>/assets/images/logo_lart_with_text.jpg" alt="Logo-LART" style="width:46qpx;height:67px;">
            <a class="navbar-brand" href="<?= base_url() ?>">FOCUS Administration Panel</a>
         </div>
         <!-- /.navbar-header -->

         <ul class="nav navbar-top-links navbar-right">

            <li class="dropdown">
               <a class="dropdown-toggle" data-toggle="dropdown" href="#">
                  <i class="fa fa-user fa-fw"></i>  <i class="fa fa-caret-down"></i>
               </a>
               <ul class="dropdown-menu dropdown-user">
                  <li><a href="<?= base_url()?>index.php/user_profiles/edit_profile/"><i class="fa fa-user fa-fw"></i> User Profile</a>
                  </li>
                  <li><a href="#"><i class="fa fa-gear fa-fw"></i> Settings</a>
                  </li>
                  <li class="divider"></li>
                  <li><a href="<?= base_url()?>index.php/r2_session_manager/logout"><i class="fa fa-sign-out fa-fw"></i> Logout</a>
                  </li>
               </ul>
               <!-- /.dropdown-user -->
            </li>
            <!-- /.dropdown -->
         </ul>
         <!-- /.navbar-top-links -->