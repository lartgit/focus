<!DOCTYPE html>
<html lang="en">

    <?= $controller->load->view($controller->_view_header, $viewData, true); ?>

    <body>
       <div id="wrapper">
          <!-- Navigation -->
          <nav class="navbar navbar-default navbar-static-top" role="navigation" style="margin-bottom: 0">

             <!-- Top Navigation Bar -->
             <?= $controller->load->view('main/top_nav_bar', $viewData, true); ?>

             <!-- Side Menu -->
             <?= $controller->load->view($controller->_view_side_menu, $viewData, true); ?>
          </nav>

          <div id="page-wrapper">
             <?php if (isset($view_file_name)): ?>
                <?= $controller->load->view($view_file_name, $viewData, true) ?>
             <?php else: ?>
                <h2>No View Selected</h2>
             <?php endif; ?>
          </div>
       </div>

       <!-- Footer-->
       <?= $controller->load->view($controller->_view_footer, $viewData, true); ?>

       <!-- Queries -->
       <?php if ($controller->is_developing_mode()): ?>
          <?php $viewData->view_name = $view_file_name ?>
          <?php $viewData->queries = $controller->performed_queries() ?>
          <?= $controller->load->view($this->_view_queries, $viewData, TRUE); ?>
       <?php endif; ?>
    </body>

</html>