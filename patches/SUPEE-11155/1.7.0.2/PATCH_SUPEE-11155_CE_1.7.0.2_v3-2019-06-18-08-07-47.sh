#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-11155_CE_1702 | CE_1.7.0.2 | v1 | 3d9cd262c288d960acd0904af67141d6121c7bb2 | Fri Jun 14 21:16:40 2019 +0000 | 54220b66866b10aad00e5a7bb73dcae83b4f8aa0..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index a7e96df68be..eb3eb5e63c2 100644
--- app/Mage.php
+++ app/Mage.php
@@ -812,9 +812,9 @@ final class Mage
             ',',
             (string) self::getConfig()->getNode('dev/log/allowedFileExtensions', Mage_Core_Model_Store::DEFAULT_CODE)
         );
-        $logValidator = new Zend_Validate_File_Extension($_allowedFileExtensions);
         $logDir = self::getBaseDir('var') . DS . 'log';
-        if (!$logValidator->isValid($logDir . DS . $file)) {
+        $validatedFileExtension = pathinfo($file, PATHINFO_EXTENSION);
+        if (!$validatedFileExtension || !in_array($validatedFileExtension, $_allowedFileExtensions)) {
             return;
         }
 
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index a672f4ef350..61c6134964d 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -57,7 +57,7 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (in_array($this->getBlockName(), $disallowedBlockNames)) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
         }
-        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9]+\/[-_a-zA-Z0-9\/]+$/'))) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is incorrect.');
         }
 
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index e5049b71e37..2dca27d10cd 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -567,7 +567,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->userExists()) {
-            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email aleady exists.');
+            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email already exists.');
         }
 
         if (count($errors) === 0) {
diff --git app/code/core/Mage/AdminNotification/etc/system.xml app/code/core/Mage/AdminNotification/etc/system.xml
index fe6b6cd8384..8703a65d981 100644
--- app/code/core/Mage/AdminNotification/etc/system.xml
+++ app/code/core/Mage/AdminNotification/etc/system.xml
@@ -64,6 +64,15 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </last_update>
+                        <feed_url>
+                            <label>Feed Url</label>
+                            <frontend_type>text</frontend_type>
+                            <backend_model>adminhtml/system_config_backend_protected</backend_model>
+                            <sort_order>3</sort_order>
+                            <show_in_default>0</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </feed_url>
                     </fields>
                 </adminnotification>
             </groups>
diff --git app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
index d6355a6b30b..a96a05d7d0e 100644
--- app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Api_Role_Grid_User extends Mage_Adminhtml_Block_Widge
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('api/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index 16390685723..79eea75cda2 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -155,6 +155,8 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
             // Hide price if needed
             foreach ($attributes as &$attribute) {
                 $attribute['label'] = $this->escapeHtml($attribute['label']);
+                $attribute['frontend_label'] = $this->escapeHtml($attribute['frontend_label']);
+                $attribute['store_label'] = $this->escapeHtml($attribute['store_label']);
                 if (isset($attribute['values']) && is_array($attribute['values'])) {
                     foreach ($attribute['values'] as &$attributeValue) {
                         if (!$this->getCanReadPrice()) {
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index be865af6b7a..871c32130bf 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
@@ -56,6 +56,12 @@ class Mage_Adminhtml_Block_Newsletter_Queue_Preview extends Mage_Adminhtml_Block
         if(!$storeId) {
             $storeId = Mage::app()->getDefaultStoreView()->getId();
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         Varien_Profiler::start("newsletter_queue_proccessing");
         $vars = array();
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
index 0612e0ce163..6110084b75f 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
@@ -46,6 +46,12 @@ class Mage_Adminhtml_Block_Newsletter_Template_Preview extends Mage_Adminhtml_Bl
             $template->setTemplateText($this->getRequest()->getParam('text'));
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         $storeId = (int)$this->getRequest()->getParam('store_id');
         if(!$storeId) {
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
index 00a2d1d3e89..91e291cc536 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Permissions_Role_Grid_User extends Mage_Adminhtml_Blo
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('admin/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
index 2054d2c7727..e8dc3b5ad2e 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
@@ -76,6 +76,7 @@ class Mage_Adminhtml_Block_Sales_Creditmemo_Grid extends Mage_Adminhtml_Block_Wi
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
index fb74a8f5395..3de55ad0c8b 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
@@ -77,6 +77,7 @@ class Mage_Adminhtml_Block_Sales_Invoice_Grid extends Mage_Adminhtml_Block_Widge
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
index ff2cbf72c0f..eb900518d33 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
@@ -34,7 +34,10 @@ class Mage_Adminhtml_Block_Sales_Order_Create_Header extends Mage_Adminhtml_Bloc
     protected function _toHtml()
     {
         if ($this->_getSession()->getOrder()->getId()) {
-            return '<h3 class="icon-head head-sales-order">'.Mage::helper('sales')->__('Edit Order #%s', $this->_getSession()->getOrder()->getIncrementId()).'</h3>';
+            return '<h3 class="icon-head head-sales-order">' . Mage::helper('sales')->__(
+                'Edit Order #%s',
+                $this->escapeHtml($this->_getSession()->getOrder()->getIncrementId())
+            ) . '</h3>';
         }
 
         $customerId = $this->getCustomerId();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
index 952f116126b..9737d2cb0d2 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
@@ -67,10 +67,15 @@ class Mage_Adminhtml_Block_Sales_Order_Creditmemo_Create extends Mage_Adminhtml_
     public function getHeaderText()
     {
         if ($this->getCreditmemo()->getInvoice()) {
-            $header = Mage::helper('sales')->__('New Credit Memo for Invoice #%s', $this->getCreditmemo()->getInvoice()->getIncrementId());
-        }
-        else {
-            $header = Mage::helper('sales')->__('New Credit Memo for Order #%s', $this->getCreditmemo()->getOrder()->getRealOrderId());
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Invoice #%s',
+                $this->escapeHtml($this->getCreditmemo()->getInvoice()->getIncrementId())
+            );
+        } else {
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Order #%s',
+                $this->escapeHtml($this->getCreditmemo()->getOrder()->getRealOrderId())
+            );
         }
 
         return $header;
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index 6a976c93ff2..1f9f5be9e97 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
@@ -65,10 +65,11 @@ class Mage_Adminhtml_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Widget_
     {
 
         $this->addColumn('real_order_id', array(
-            'header'=> Mage::helper('sales')->__('Order #'),
-            'width' => '80px',
-            'type'  => 'text',
-            'index' => 'increment_id',
+            'header' => Mage::helper('sales')->__('Order #'),
+            'width'  => '80px',
+            'type'   => 'text',
+            'index'  => 'increment_id',
+            'escape' => true,
         ));
 
         if (!Mage::app()->isSingleStoreMode()) {
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
index bf0023f6fe1..01755f7eb3d 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
@@ -64,8 +64,14 @@ class Mage_Adminhtml_Block_Sales_Order_Invoice_Create extends Mage_Adminhtml_Blo
     public function getHeaderText()
     {
         return ($this->getInvoice()->getOrder()->getForcedDoShipmentWithInvoice())
-            ? Mage::helper('sales')->__('New Invoice and Shipment for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId())
-            : Mage::helper('sales')->__('New Invoice for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId());
+            ? Mage::helper('sales')->__(
+                'New Invoice and Shipment for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            )
+            : Mage::helper('sales')->__(
+                'New Invoice for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            );
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
index 8fe63a73e7e..9c8ea34124c 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
@@ -59,7 +59,10 @@ class Mage_Adminhtml_Block_Sales_Order_Shipment_Create extends Mage_Adminhtml_Bl
 
     public function getHeaderText()
     {
-        $header = Mage::helper('sales')->__('New Shipment for Order #%s', $this->getShipment()->getOrder()->getRealOrderId());
+        $header = Mage::helper('sales')->__(
+            'New Shipment for Order #%s',
+            $this->escapeHtml($this->getShipment()->getOrder()->getRealOrderId())
+        );
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
index ac41314314f..c4b6f197edc 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -295,6 +295,16 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
     {
         return $this->getUrl('*/*/reviewPayment', array('action' => $action));
     }
+
+    /**
+     * Return header for view grid
+     *
+     * @return string
+     */
+    public function getHeaderHtml()
+    {
+        return '<h3 class="' . $this->getHeaderCssClass() . '">' . $this->escapeHtml($this->getHeaderText()) . '</h3>';
+    }
 //
 //    /**
 //     * Return URL for accept payment action
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
index 1ffe3ba13af..84ad1bfdbf6 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
@@ -88,6 +88,7 @@ class Mage_Adminhtml_Block_Sales_Shipment_Grid extends Mage_Adminhtml_Block_Widg
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
index c8f8fe5fe14..7c87fb3b2c6 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
@@ -82,7 +82,8 @@ class Mage_Adminhtml_Block_Sales_Transactions_Grid extends Mage_Adminhtml_Block_
         $this->addColumn('increment_id', array(
             'header'    => Mage::helper('sales')->__('Order ID'),
             'index'     => 'increment_id',
-            'type'      => 'text'
+            'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('txn_id', array(
diff --git app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
index 80cdb05fe1d..70e6efe8b7c 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
@@ -51,11 +51,12 @@ class Mage_Adminhtml_Block_System_Email_Template_Preview extends Mage_Adminhtml_
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
 
-        /* @var $filter Mage_Core_Model_Input_Filter_MaliciousCode */
-        $filter = Mage::getSingleton('core/input_filter_maliciousCode');
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
 
         $template->setTemplateText(
-            $filter->filter($template->getTemplateText())
+            $this->maliciousCodeFilter($template->getTemplateText())
         );
 
         Varien_Profiler::start("email_template_proccessing");
diff --git app/code/core/Mage/Adminhtml/Block/Template.php app/code/core/Mage/Adminhtml/Block/Template.php
index a750e7f3b13..de3be49944c 100644
--- app/code/core/Mage/Adminhtml/Block/Template.php
+++ app/code/core/Mage/Adminhtml/Block/Template.php
@@ -80,4 +80,15 @@ class Mage_Adminhtml_Block_Template extends Mage_Core_Block_Template
         Mage::dispatchEvent('adminhtml_block_html_before', array('block' => $this));
         return parent::_toHtml();
     }
+
+    /**
+     * Deleting script tags from string
+     *
+     * @param string $html
+     * @return string
+     */
+    public function maliciousCodeFilter($html)
+    {
+        return Mage::getSingleton('core/input_filter_maliciousCode')->filter($html);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
index 786864e37a1..dd145444729 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
@@ -114,9 +114,9 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
             }
             $out = '<a href="#" name="' . $this->getColumn()->getId() . '" title="' . $nDir
                    . '" class="' . $className . '"><span class="sort-title">'
-                   . $this->getColumn()->getHeader().'</span></a>';
+                   . $this->escapeHtml($this->getColumn()->getHeader()) . '</span></a>';
         } else {
-            $out = $this->getColumn()->getHeader();
+            $out = $this->escapeHtml($this->getColumn()->getHeader());
         }
         return $out;
     }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 84389b17507..ea92ac4d484 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -180,8 +180,11 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
     protected function _getXpathBlockValidationExpression() {
         $xpath = "";
         if (count($this->_disallowedBlock)) {
-            $xpath = "//block[@type='";
-            $xpath .= implode("'] | //block[@type='", $this->_disallowedBlock) . "']";
+            foreach ($this->_disallowedBlock as $key => $value) {
+                $xpath .= $key > 0 ? " | " : '';
+                $xpath .= "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
+                $xpath .= "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
+            }
         }
         return $xpath;
     }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
index 9e2563a0e1a..f21c2b55d11 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
@@ -35,6 +35,8 @@ class Mage_Adminhtml_Model_System_Config_Backend_Baseurl extends Mage_Core_Model
             $parsedUrl = parse_url($value);
             if (!isset($parsedUrl['scheme']) || !isset($parsedUrl['host'])) {
                 Mage::throwException(Mage::helper('core')->__('The %s you entered is invalid. Please make sure that it follows "http://domain.com/" format.', $this->getFieldConfig()->label));
+            } elseif (('https' != $parsedUrl['scheme']) && ('http' != $parsedUrl['scheme'])) {
+                Mage::throwException(Mage::helper('core')->__('Invalid URL scheme.'));
             }
         }
 
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
index 19ee8d6d79d..0d268f672b8 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
@@ -34,6 +34,27 @@
  */
 class Mage_Adminhtml_Model_System_Config_Backend_Locale extends Mage_Core_Model_Config_Data
 {
+    /**
+     * Validate data before save data
+     *
+     * @return Mage_Core_Model_Abstract
+     * @throws Mage_Core_Exception
+     */
+    protected function _beforeSave()
+    {
+        $allCurrenciesOptions = Mage::getSingleton('adminhtml/system_config_source_locale_currency_all')
+            ->toOptionArray(true);
+
+        $allCurrenciesValues = array_column($allCurrenciesOptions, 'value');
+
+        foreach ($this->getValue() as $currency) {
+            if (!in_array($currency, $allCurrenciesValues)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Currency doesn\'t exist.'));
+            }
+        }
+
+        return parent::_beforeSave();
+    }
 
     /**
      * Enter description here...
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
index df16b1a1e3a..f1769d917d0 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
@@ -31,11 +31,19 @@
 class Mage_Adminhtml_Model_System_Config_Backend_Serialized_Array extends Mage_Adminhtml_Model_System_Config_Backend_Serialized
 {
     /**
-     * Unset array element with '__empty' key
+     * Check object existence in incoming data and unset array element with '__empty' key
      *
+     * @throws Mage_Core_Exception
+     * @return void
      */
     protected function _beforeSave()
     {
+        try {
+            Mage::helper('core/unserializeArray')->unserialize(serialize($this->getValue()));
+        } catch (Exception $e) {
+            Mage::throwException(Mage::helper('adminhtml')->__('Serialized data is incorrect'));
+        }
+
         $value = $this->getValue();
         if (is_array($value)) {
             unset($value['__empty']);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
index 0fb2835f535..5b95386c2e4 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
@@ -157,6 +157,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
             /** @var $helperCatalog Mage_Catalog_Helper_Data */
             $helperCatalog = Mage::helper('catalog');
             //labels
+            $data['frontend_label'] = (array) $data['frontend_label'];
             foreach ($data['frontend_label'] as & $value) {
                 if ($value) {
                     $value = $helperCatalog->stripTags($value);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
index d8440d3e0d5..3e4c866e0a4 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
@@ -41,6 +41,17 @@ class Mage_Adminhtml_Catalog_Product_ReviewController extends Mage_Adminhtml_Con
      */
     protected $_publicActions = array('edit');
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions(array('delete', 'massDelete'));
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Catalog'))
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index 6daf0a0a827..d389b5f8ebe 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -541,7 +541,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         catch (Mage_Eav_Model_Entity_Attribute_Exception $e) {
             $response->setError(true);
             $response->setAttribute($e->getAttributeCode());
-            $response->setMessage($e->getMessage());
+            $response->setMessage(Mage::helper('core')->escapeHtml($e->getMessage()));
         } catch (Mage_Core_Exception $e) {
             $response->setError(true);
             $response->setMessage($e->getMessage());
diff --git app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
index 12483a0b819..ea808e1efd6 100644
--- app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
+++ app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
@@ -33,6 +33,17 @@
  */
 class Mage_Adminhtml_Checkout_AgreementController extends Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Sales'))->_title($this->__('Terms and Conditions'));
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index 0894876a67c..2f5cea0c013 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -167,6 +167,11 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
         }
 
         try {
+            $allowedHtmlTags = ['text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->addData($request->getParams())
                 ->setTemplateSubject($request->getParam('subject'))
                 ->setTemplateCode($request->getParam('code'))
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
index 548285c0613..8f602698259 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
@@ -133,6 +133,9 @@ class Mage_Adminhtml_Promo_CatalogController extends Mage_Adminhtml_Controller_A
                     array('request' => $this->getRequest())
                 );
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 if ($id = $this->getRequest()->getParam('rule_id')) {
                     $model->load($id);
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
index 7806a075b59..95cf84d920c 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
@@ -133,6 +133,9 @@ class Mage_Adminhtml_Promo_QuoteController extends Mage_Adminhtml_Controller_Act
                     'adminhtml_controller_salesrule_prepare_save',
                     array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 $id = $this->getRequest()->getParam('rule_id');
                 if ($id) {
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
index 376afd7bf17..261786df417 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
@@ -146,6 +146,13 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
          * Saving order data
          */
         if ($data = $this->getRequest()->getPost('order')) {
+            if (
+                array_key_exists('comment', $data)
+                && array_key_exists('reserved_order_id', $data['comment'])
+            ) {
+                unset($data['comment']['reserved_order_id']);
+            }
+
             $this->_getOrderCreateModel()->importPostData($data);
         }
 
@@ -476,10 +483,20 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
 
     /**
      * Saving quote and create order
+     *
+     * @throws Mage_Core_Exception
      */
     public function saveAction()
     {
         try {
+            $orderData = $this->getRequest()->getPost('order');
+            if (
+                array_key_exists('reserved_order_id', $orderData['comment'])
+                && Mage::helper('adminhtml/sales')->hasTags($orderData['comment']['reserved_order_id'])
+            ) {
+                Mage::throwException($this->__('Invalid order data.'));
+            }
+
             $this->_processActionData('save');
             if ($paymentData = $this->getRequest()->getPost('payment')) {
                 $this->_getOrderCreateModel()->setPaymentData($paymentData);
diff --git app/code/core/Mage/Adminhtml/controllers/SitemapController.php app/code/core/Mage/Adminhtml/controllers/SitemapController.php
index 4f5c381c57e..847133f76f4 100644
--- app/code/core/Mage/Adminhtml/controllers/SitemapController.php
+++ app/code/core/Mage/Adminhtml/controllers/SitemapController.php
@@ -33,6 +33,11 @@
  */
 class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Maximum sitemap name length
+     */
+    const MAXIMUM_SITEMAP_NAME_LENGTH = 32;
+
     /**
      * Controller predispatch method
      *
@@ -141,6 +146,19 @@ class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
             if (!empty($data['sitemap_filename']) && !empty($data['sitemap_path'])) {
                 $path = rtrim($data['sitemap_path'], '\\/')
                       . DS . $data['sitemap_filename'];
+
+                // check filename length
+                if (strlen($data['sitemap_filename']) > self::MAXIMUM_SITEMAP_NAME_LENGTH) {
+                    Mage::getSingleton('adminhtml/session')->addError(
+                        Mage::helper('sitemap')->__(
+                            'Please enter a sitemap name with at most %s characters.',
+                            self::MAXIMUM_SITEMAP_NAME_LENGTH
+                        ));
+                    $this->_redirect('*/*/edit', array(
+                        'sitemap_id' => $this->getRequest()->getParam('sitemap_id')
+                    ));
+                    return;
+                }
                 /** @var $validator Mage_Core_Model_File_Validator_AvailablePath */
                 $validator = Mage::getModel('core/file_validator_availablePath');
                 /** @var $helper Mage_Adminhtml_Helper_Catalog */
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index 1310399fc49..66ddbf2c13d 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
@@ -89,6 +89,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         $this->renderLayout();
     }
 
+    /**
+     * Save action
+     *
+     * @throws Mage_Core_Exception
+     */
     public function saveAction()
     {
         $request = $this->getRequest();
@@ -102,6 +107,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         }
 
         try {
+            $allowedHtmlTags = ['template_text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->setTemplateSubject($request->getParam('template_subject'))
                 ->setTemplateCode($request->getParam('template_code'))
 /*
diff --git app/code/core/Mage/Catalog/Helper/Product.php app/code/core/Mage/Catalog/Helper/Product.php
old mode 100755
new mode 100644
index 3b2659bcf01..77230c6270e
--- app/code/core/Mage/Catalog/Helper/Product.php
+++ app/code/core/Mage/Catalog/Helper/Product.php
@@ -468,4 +468,41 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
     {
         return $this->_skipSaleableCheck;
     }
+
+    /**
+     * Get default product value by field name
+     *
+     * @param string $fieldName
+     * @param string $productType
+     * @return int
+     */
+    public function getDefaultProductValue($fieldName, $productType)
+    {
+        $fieldData = $this->getFieldset($fieldName) ? (array) $this->getFieldset($fieldName) : null;
+        if (
+            count($fieldData)
+            && array_key_exists($productType, $fieldData['product_type'])
+            && (bool)$fieldData['use_config']
+        ) {
+            return $fieldData['inventory'];
+        }
+        return self::DEFAULT_QTY;
+    }
+
+    /**
+     * Return array from config by fieldset name and area
+     *
+     * @param null|string $field
+     * @param string $fieldset
+     * @param string $area
+     * @return array|null
+     */
+    public function getFieldset($field = null, $fieldset = 'catalog_product_dataflow', $area = 'admin')
+    {
+        $fieldsetData = Mage::getConfig()->getFieldset($fieldset, $area);
+        if ($fieldsetData) {
+            return $fieldsetData ? $fieldsetData->$field : $fieldsetData;
+        }
+        return $fieldsetData;
+    }
 }
diff --git app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php.orig app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php.orig
deleted file mode 100644
index 5e9bdea59bb..00000000000
--- app/code/core/Mage/Catalog/Model/Product/Option/Type/File.php.orig
+++ /dev/null
@@ -1,823 +0,0 @@
-<?php
-/**
- * Magento
- *
- * NOTICE OF LICENSE
- *
- * This source file is subject to the Open Software License (OSL 3.0)
- * that is bundled with this package in the file LICENSE.txt.
- * It is also available through the world-wide-web at this URL:
- * http://opensource.org/licenses/osl-3.0.php
- * If you did not receive a copy of the license and are unable to
- * obtain it through the world-wide-web, please send an email
- * to license@magentocommerce.com so we can send you a copy immediately.
- *
- * DISCLAIMER
- *
- * Do not edit or add to this file if you wish to upgrade Magento to newer
- * versions in the future. If you wish to customize Magento for your
- * needs please refer to http://www.magentocommerce.com for more information.
- *
- * @category    Mage
- * @package     Mage_Catalog
- * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
- */
-
-/**
- * Catalog product option file type
- *
- * @category   Mage
- * @package    Mage_Catalog
- * @author     Magento Core Team <core@magentocommerce.com>
- */
-class Mage_Catalog_Model_Product_Option_Type_File extends Mage_Catalog_Model_Product_Option_Type_Default
-{
-    /**
-     * Url for custom option download controller
-     * @var string
-     */
-    protected $_customOptionDownloadUrl = 'sales/download/downloadCustomOption';
-
-    public function isCustomizedView()
-    {
-        return true;
-    }
-
-    /**
-     * Return option html
-     *
-     * @param array $optionInfo
-     * @return string
-     */
-    public function getCustomizedView($optionInfo)
-    {
-        try {
-            if (isset($optionInfo['option_value'])) {
-                return $this->_getOptionHtml($optionInfo['option_value']);
-            } elseif (isset($optionInfo['value'])) {
-                return $optionInfo['value'];
-            }
-        } catch (Exception $e) {
-            return $optionInfo['value'];
-        }
-    }
-
-    /**
-     * Returns additional params for processing options
-     *
-     * @return Varien_Object
-     */
-    protected function _getProcessingParams()
-    {
-        $buyRequest = $this->getRequest();
-        $params = $buyRequest->getData('_processing_params');
-        /*
-         * Notice check for params to be Varien_Object - by using object we protect from
-         * params being forged and contain data from user frontend input
-         */
-        if ($params instanceof Varien_Object) {
-            return $params;
-        }
-        return new Varien_Object();
-    }
-
-    /**
-     * Returns file info array if we need to get file from already existing file.
-     * Or returns null, if we need to get file from uploaded array.
-     *
-     * @return null|array
-     */
-    protected function _getCurrentConfigFileInfo()
-    {
-        $option = $this->getOption();
-        $optionId = $option->getId();
-        $processingParams = $this->_getProcessingParams();
-        $buyRequest = $this->getRequest();
-
-        // Check maybe restore file from config requested
-        $optionActionKey = 'options_' . $optionId . '_file_action';
-        if ($buyRequest->getData($optionActionKey) == 'save_old') {
-            $fileInfo = array();
-            $currentConfig = $processingParams->getCurrentConfig();
-            if ($currentConfig) {
-                $fileInfo = $currentConfig->getData('options/' . $optionId);
-            }
-            return $fileInfo;
-        }
-        return null;
-    }
-
-    /**
-     * Validate user input for option
-     *
-     * @throws Mage_Core_Exception
-     * @param array $values All product option values, i.e. array (option_id => mixed, option_id => mixed...)
-     * @return Mage_Catalog_Model_Product_Option_Type_File
-     */
-    public function validateUserValue($values)
-    {
-        Mage::getSingleton('checkout/session')->setUseNotice(false);
-
-        $this->setIsValid(true);
-        $option = $this->getOption();
-
-        /*
-         * Check whether we receive uploaded file or restore file by: reorder/edit configuration or
-         * previous configuration with no newly uploaded file
-         */
-        $fileInfo = null;
-        if (isset($values[$option->getId()]) && is_array($values[$option->getId()])) {
-            // Legacy style, file info comes in array with option id index
-            $fileInfo = $values[$option->getId()];
-        } else {
-            /*
-             * New recommended style - file info comes in request processing parameters and we
-             * sure that this file info originates from Magento, not from manually formed POST request
-             */
-            $fileInfo = $this->_getCurrentConfigFileInfo();
-        }
-        if ($fileInfo !== null) {
-            if (is_array($fileInfo) && $this->_validateFile($fileInfo)) {
-                $value = $fileInfo;
-            } else {
-                $value = null;
-            }
-            $this->setUserValue($value);
-            return $this;
-        }
-
-        // Process new uploaded file
-        try {
-            $this->_validateUploadedFile();
-        } catch (Exception $e) {
-            if ($this->getSkipCheckRequiredOption()) {
-                $this->setUserValue(null);
-                return $this;
-            } else {
-                Mage::throwException($e->getMessage());
-            }
-        }
-        return $this;
-    }
-
-    /**
-     * Validate uploaded file
-     *
-     * @throws Mage_Core_Exception
-     * @return Mage_Catalog_Model_Product_Option_Type_File
-     */
-    protected function _validateUploadedFile()
-    {
-        $option = $this->getOption();
-        $processingParams = $this->_getProcessingParams();
-
-        /**
-         * Upload init
-         */
-        $upload   = new Zend_File_Transfer_Adapter_Http();
-        $file = $processingParams->getFilesPrefix() . 'options_' . $option->getId() . '_file';
-        try {
-            $runValidation = $option->getIsRequire() || $upload->isUploaded($file);
-            if (!$runValidation) {
-                $this->setUserValue(null);
-                return $this;
-            }
-
-            $fileInfo = $upload->getFileInfo($file);
-            $fileInfo = $fileInfo[$file];
-            $fileInfo['title'] = $fileInfo['name'];
-
-        } catch (Exception $e) {
-            // when file exceeds the upload_max_filesize, $_FILES is empty
-            if (isset($_SERVER['CONTENT_LENGTH']) && $_SERVER['CONTENT_LENGTH'] > $this->_getUploadMaxFilesize()) {
-                $this->setIsValid(false);
-                $value = $this->_bytesToMbytes($this->_getUploadMaxFilesize());
-                Mage::throwException(
-                    Mage::helper('catalog')->__("The file you uploaded is larger than %s Megabytes allowed by server", $value)
-                );
-            } else {
-                switch($this->getProcessMode())
-                {
-                    case Mage_Catalog_Model_Product_Type_Abstract::PROCESS_MODE_FULL:
-                        Mage::throwException(
-                            Mage::helper('catalog')->__('Please specify the product\'s required option(s).')
-                        );
-                        break;
-                    default:
-                        $this->setUserValue(null);
-                        break;
-                }
-                return $this;
-            }
-        }
-
-        /**
-         * Option Validations
-         */
-
-        // Image dimensions
-        $_dimentions = array();
-        if ($option->getImageSizeX() > 0) {
-            $_dimentions['maxwidth'] = $option->getImageSizeX();
-        }
-        if ($option->getImageSizeY() > 0) {
-            $_dimentions['maxheight'] = $option->getImageSizeY();
-        }
-        if (count($_dimentions) > 0) {
-            $upload->addValidator('ImageSize', false, $_dimentions);
-        }
-
-        // File extension
-        $_allowed = $this->_parseExtensionsString($option->getFileExtension());
-        if ($_allowed !== null) {
-            $upload->addValidator('Extension', false, $_allowed);
-        } else {
-            $_forbidden = $this->_parseExtensionsString($this->getConfigData('forbidden_extensions'));
-            if ($_forbidden !== null) {
-                $upload->addValidator('ExcludeExtension', false, $_forbidden);
-            }
-        }
-
-        // Maximum filesize
-        $upload->addValidator('FilesSize', false, array('max' => $this->_getUploadMaxFilesize()));
-
-        /**
-         * Upload process
-         */
-
-        $this->_initFilesystem();
-
-        if ($upload->isUploaded($file) && $upload->isValid($file)) {
-
-            $extension = pathinfo(strtolower($fileInfo['name']), PATHINFO_EXTENSION);
-
-            $fileName = Mage_Core_Model_File_Uploader::getCorrectFileName($fileInfo['name']);
-            $dispersion = Mage_Core_Model_File_Uploader::getDispretionPath($fileName);
-
-            $filePath = $dispersion;
-            $fileHash = md5(file_get_contents($fileInfo['tmp_name']));
-            $filePath .= DS . $fileHash . '.' . $extension;
-            $fileFullPath = $this->getQuoteTargetDir() . $filePath;
-
-            $upload->addFilter('Rename', array(
-                'target' => $fileFullPath,
-                'overwrite' => true
-            ));
-
-            $this->getProduct()->getTypeInstance(true)->addFileQueue(array(
-                'operation' => 'receive_uploaded_file',
-                'src_name'  => $file,
-                'dst_name'  => $fileFullPath,
-                'uploader'  => $upload,
-                'option'    => $this,
-            ));
-
-            $_width = 0;
-            $_height = 0;
-            if (is_readable($fileInfo['tmp_name'])) {
-                $_imageSize = getimagesize($fileInfo['tmp_name']);
-                if ($_imageSize) {
-                    $_width = $_imageSize[0];
-                    $_height = $_imageSize[1];
-                }
-            }
-
-            $this->setUserValue(array(
-                'type'          => $fileInfo['type'],
-                'title'         => $fileInfo['name'],
-                'quote_path'    => $this->getQuoteTargetDir(true) . $filePath,
-                'order_path'    => $this->getOrderTargetDir(true) . $filePath,
-                'fullpath'      => $fileFullPath,
-                'size'          => $fileInfo['size'],
-                'width'         => $_width,
-                'height'        => $_height,
-                'secret_key'    => substr($fileHash, 0, 20),
-            ));
-
-        } elseif ($upload->getErrors()) {
-            $errors = $this->_getValidatorErrors($upload->getErrors(), $fileInfo);
-
-            if (count($errors) > 0) {
-                $this->setIsValid(false);
-                Mage::throwException( implode("\n", $errors) );
-            }
-        } else {
-            $this->setIsValid(false);
-            Mage::throwException(Mage::helper('catalog')->__('Please specify the product required option(s)'));
-        }
-        return $this;
-    }
-
-    /**
-     * Validate file
-     *
-     * @throws Mage_Core_Exception
-     * @param array $optionValue
-     * @return Mage_Catalog_Model_Product_Option_Type_Default
-     */
-    protected function _validateFile($optionValue)
-    {
-        $option = $this->getOption();
-        /**
-         * @see Mage_Catalog_Model_Product_Option_Type_File::_validateUploadFile()
-         *              There setUserValue() sets correct fileFullPath only for
-         *              quote_path. So we must form both full paths manually and
-         *              check them.
-         */
-        $checkPaths = array();
-        if (isset($optionValue['quote_path'])) {
-            $checkPaths[] = Mage::getBaseDir() . $optionValue['quote_path'];
-        }
-        if (isset($optionValue['order_path']) && !$this->getUseQuotePath()) {
-            $checkPaths[] = Mage::getBaseDir() . $optionValue['order_path'];
-        }
-
-        $fileFullPath = null;
-        foreach ($checkPaths as $path) {
-            if (!is_file($path)) {
-                if (!Mage::helper('core/file_storage_database')->saveFileToFilesystem($fileFullPath)) {
-                    continue;
-                }
-            }
-            $fileFullPath = $path;
-            break;
-        }
-
-        if ($fileFullPath === null) {
-            return false;
-        }
-
-        $validatorChain = new Zend_Validate();
-
-        $_dimentions = array();
-
-        if ($option->getImageSizeX() > 0) {
-            $_dimentions['maxwidth'] = $option->getImageSizeX();
-        }
-        if ($option->getImageSizeY() > 0) {
-            $_dimentions['maxheight'] = $option->getImageSizeY();
-        }
-        if (count($_dimentions) > 0 && !$this->_isImage($fileFullPath)) {
-            return false;
-        }
-        if (count($_dimentions) > 0) {
-            $validatorChain->addValidator(
-                new Zend_Validate_File_ImageSize($_dimentions)
-            );
-        }
-
-        // File extension
-        $_allowed = $this->_parseExtensionsString($option->getFileExtension());
-        if ($_allowed !== null) {
-            $validatorChain->addValidator(new Zend_Validate_File_Extension($_allowed));
-        } else {
-            $_forbidden = $this->_parseExtensionsString($this->getConfigData('forbidden_extensions'));
-            if ($_forbidden !== null) {
-                $validatorChain->addValidator(new Zend_Validate_File_ExcludeExtension($_forbidden));
-            }
-        }
-
-        // Maximum filesize
-        $validatorChain->addValidator(
-                new Zend_Validate_File_FilesSize(array('max' => $this->_getUploadMaxFilesize()))
-        );
-
-
-        if ($validatorChain->isValid($fileFullPath)) {
-            $ok = is_readable($fileFullPath)
-                && isset($optionValue['secret_key'])
-                && substr(md5(file_get_contents($fileFullPath)), 0, 20) == $optionValue['secret_key'];
-
-            return $ok;
-        } elseif ($validatorChain->getErrors()) {
-            $errors = $this->_getValidatorErrors($validatorChain->getErrors(), $optionValue);
-
-            if (count($errors) > 0) {
-                $this->setIsValid(false);
-                Mage::throwException( implode("\n", $errors) );
-            }
-        } else {
-            $this->setIsValid(false);
-            Mage::throwException(Mage::helper('catalog')->__('Please specify the product required option(s)'));
-        }
-    }
-
-    /**
-     * Get Error messages for validator Errors
-     * @param array $errors Array of validation failure message codes @see Zend_Validate::getErrors()
-     * @param array $fileInfo File info
-     * @return array Array of error messages
-     */
-    protected function _getValidatorErrors($errors, $fileInfo)
-    {
-        $option = $this->getOption();
-        $result = array();
-        foreach ($errors as $errorCode) {
-            if ($errorCode == Zend_Validate_File_ExcludeExtension::FALSE_EXTENSION) {
-                $result[] = Mage::helper('catalog')->__("The file '%s' for '%s' has an invalid extension", $fileInfo['title'], $option->getTitle());
-            } elseif ($errorCode == Zend_Validate_File_Extension::FALSE_EXTENSION) {
-                $result[] = Mage::helper('catalog')->__("The file '%s' for '%s' has an invalid extension", $fileInfo['title'], $option->getTitle());
-            } elseif ($errorCode == Zend_Validate_File_ImageSize::WIDTH_TOO_BIG
-                || $errorCode == Zend_Validate_File_ImageSize::HEIGHT_TOO_BIG)
-            {
-                $result[] = Mage::helper('catalog')->__("Maximum allowed image size for '%s' is %sx%s px.", $option->getTitle(), $option->getImageSizeX(), $option->getImageSizeY());
-            } elseif ($errorCode == Zend_Validate_File_FilesSize::TOO_BIG) {
-                $result[] = Mage::helper('catalog')->__("The file '%s' you uploaded is larger than %s Megabytes allowed by server", $fileInfo['title'], $this->_bytesToMbytes($this->_getUploadMaxFilesize()));
-            }
-        }
-        return $result;
-    }
-
-    /**
-     * Prepare option value for cart
-     *
-     * @return mixed Prepared option value
-     */
-    public function prepareForCart()
-    {
-        $option = $this->getOption();
-        $optionId = $option->getId();
-        $buyRequest = $this->getRequest();
-
-        // Prepare value and fill buyRequest with option
-        $requestOptions = $buyRequest->getOptions();
-        if ($this->getIsValid() && $this->getUserValue() !== null) {
-            $value = $this->getUserValue();
-
-            // Save option in request, because we have no $_FILES['options']
-            $requestOptions[$this->getOption()->getId()] = $value;
-            $result = serialize($value);
-        } else {
-            /*
-             * Clear option info from request, so it won't be stored in our db upon
-             * unsuccessful validation. Otherwise some bad file data can happen in buyRequest
-             * and be used later in reorders and reconfigurations.
-             */
-            if (is_array($requestOptions)) {
-                unset($requestOptions[$this->getOption()->getId()]);
-            }
-            $result = null;
-        }
-        $buyRequest->setOptions($requestOptions);
-
-        // Clear action key from buy request - we won't need it anymore
-        $optionActionKey = 'options_' . $optionId . '_file_action';
-        $buyRequest->unsetData($optionActionKey);
-
-        return $result;
-    }
-
-    /**
-     * Return formatted option value for quote option
-     *
-     * @param string $optionValue Prepared for cart option value
-     * @return string
-     */
-    public function getFormattedOptionValue($optionValue)
-    {
-        if ($this->_formattedOptionValue === null) {
-            try {
-                $value = unserialize($optionValue);
-
-                $customOptionUrlParams = $this->getCustomOptionUrlParams()
-                    ? $this->getCustomOptionUrlParams()
-                    : array(
-                        'id'  => $this->getConfigurationItemOption()->getId(),
-                        'key' => $value['secret_key']
-                    );
-
-                $value['url'] = array('route' => $this->_customOptionDownloadUrl, 'params' => $customOptionUrlParams);
-
-                $this->_formattedOptionValue = $this->_getOptionHtml($value);
-                $this->getConfigurationItemOption()->setValue(serialize($value));
-                return $this->_formattedOptionValue;
-            } catch (Exception $e) {
-                return $optionValue;
-            }
-        }
-        return $this->_formattedOptionValue;
-    }
-
-    /**
-     * Format File option html
-     *
-     * @param string|array $optionValue Serialized string of option data or its data array
-     * @return string
-     */
-    protected function _getOptionHtml($optionValue)
-    {
-        $value = $this->_unserializeValue($optionValue);
-        try {
-            if (isset($value) && isset($value['width']) && isset($value['height'])
-                && $value['width'] > 0 && $value['height'] > 0
-            ) {
-                $sizes = $value['width'] . ' x ' . $value['height'] . ' ' . Mage::helper('catalog')->__('px.');
-            } else {
-                $sizes = '';
-            }
-
-            $urlRoute = !empty($value['url']['route']) ? $value['url']['route'] : '';
-            $urlParams = !empty($value['url']['params']) ? $value['url']['params'] : '';
-            $title = !empty($value['title']) ? $value['title'] : '';
-
-            return sprintf('<a href="%s" target="_blank">%s</a> %s',
-                $this->_getOptionDownloadUrl($urlRoute, $urlParams),
-                Mage::helper('core')->htmlEscape($title),
-                $sizes
-            );
-        } catch (Exception $e) {
-            Mage::throwException(Mage::helper('catalog')->__("File options format is not valid."));
-        }
-    }
-
-    /**
-     * Create a value from a storable representation
-     *
-     * @param mixed $value
-     * @return array
-     */
-    protected function _unserializeValue($value)
-    {
-        if (is_array($value)) {
-            return $value;
-        } elseif (is_string($value) && !empty($value)) {
-            return unserialize($value);
-        } else {
-            return array();
-        }
-    }
-
-    /**
-     * Return printable option value
-     *
-     * @param string $optionValue Prepared for cart option value
-     * @return string
-     */
-    public function getPrintableOptionValue($optionValue)
-    {
-        return strip_tags($this->getFormattedOptionValue($optionValue));
-    }
-
-    /**
-     * Return formatted option value ready to edit, ready to parse
-     *
-     * @param string $optionValue Prepared for cart option value
-     * @return string
-     */
-    public function getEditableOptionValue($optionValue)
-    {
-        try {
-            $value = unserialize($optionValue);
-            return sprintf('%s [%d]',
-                Mage::helper('core')->htmlEscape($value['title']),
-                $this->getConfigurationItemOption()->getId()
-            );
-
-        } catch (Exception $e) {
-            return $optionValue;
-        }
-    }
-
-    /**
-     * Parse user input value and return cart prepared value
-     *
-     * @param string $optionValue
-     * @param array $productOptionValues Values for product option
-     * @return string|null
-     */
-    public function parseOptionValue($optionValue, $productOptionValues)
-    {
-        // search quote item option Id in option value
-        if (preg_match('/\[([0-9]+)\]/', $optionValue, $matches)) {
-            $confItemOptionId = $matches[1];
-            $option = Mage::getModel('sales/quote_item_option')->load($confItemOptionId);
-            try {
-                unserialize($option->getValue());
-                return $option->getValue();
-            } catch (Exception $e) {
-                return null;
-            }
-        } else {
-            return null;
-        }
-    }
-
-    /**
-     * Prepare option value for info buy request
-     *
-     * @param string $optionValue
-     * @return mixed
-     */
-    public function prepareOptionValueForRequest($optionValue)
-    {
-        try {
-            $result = unserialize($optionValue);
-            return $result;
-        } catch (Exception $e) {
-            return null;
-        }
-    }
-
-    /**
-     * Quote item to order item copy process
-     *
-     * @return Mage_Catalog_Model_Product_Option_Type_File
-     */
-    public function copyQuoteToOrder()
-    {
-        $quoteOption = $this->getQuoteItemOption();
-        try {
-            $value = unserialize($quoteOption->getValue());
-            if (!isset($value['quote_path'])) {
-                throw new Exception();
-            }
-            $quoteFileFullPath = Mage::getBaseDir() . $value['quote_path'];
-            if (!is_file($quoteFileFullPath) || !is_readable($quoteFileFullPath)) {
-                throw new Exception();
-            }
-            $orderFileFullPath = Mage::getBaseDir() . $value['order_path'];
-            $dir = pathinfo($orderFileFullPath, PATHINFO_DIRNAME);
-            $this->_createWriteableDir($dir);
-            Mage::helper('core/file_storage_database')->copyFile($quoteFileFullPath, $orderFileFullPath);
-            @copy($quoteFileFullPath, $orderFileFullPath);
-        } catch (Exception $e) {
-            return $this;
-        }
-        return $this;
-    }
-
-    /**
-     * Main Destination directory
-     *
-     * @param boolean $relative If true - returns relative path to the webroot
-     * @return string
-     */
-    public function getTargetDir($relative = false)
-    {
-        $fullPath = Mage::getBaseDir('media') . DS . 'custom_options';
-        return $relative ? str_replace(Mage::getBaseDir(), '', $fullPath) : $fullPath;
-    }
-
-    /**
-     * Quote items destination directory
-     *
-     * @param boolean $relative If true - returns relative path to the webroot
-     * @return string
-     */
-    public function getQuoteTargetDir($relative = false)
-    {
-        return $this->getTargetDir($relative) . DS . 'quote';
-    }
-
-    /**
-     * Order items destination directory
-     *
-     * @param boolean $relative If true - returns relative path to the webroot
-     * @return string
-     */
-    public function getOrderTargetDir($relative = false)
-    {
-        return $this->getTargetDir($relative) . DS . 'order';
-    }
-
-    /**
-     * Set url to custom option download controller
-     *
-     * @param string $url
-     * @return Mage_Catalog_Model_Product_Option_Type_File
-     */
-    public function setCustomOptionDownloadUrl($url)
-    {
-        $this->_customOptionDownloadUrl = $url;
-        return $this;
-    }
-
-    /**
-     * Directory structure initializing
-     */
-    protected function _initFilesystem()
-    {
-        $this->_createWriteableDir($this->getTargetDir());
-        $this->_createWriteableDir($this->getQuoteTargetDir());
-        $this->_createWriteableDir($this->getOrderTargetDir());
-
-        // Directory listing and hotlink secure
-        $io = new Varien_Io_File();
-        $io->cd($this->getTargetDir());
-        if (!$io->fileExists($this->getTargetDir() . DS . '.htaccess')) {
-            $io->streamOpen($this->getTargetDir() . DS . '.htaccess');
-            $io->streamLock(true);
-            $io->streamWrite("Order deny,allow\nDeny from all");
-            $io->streamUnlock();
-            $io->streamClose();
-        }
-    }
-
-    /**
-     * Create Writeable directory if it doesn't exist
-     *
-     * @param string Absolute directory path
-     * @return void
-     */
-    protected function _createWriteableDir($path)
-    {
-        $io = new Varien_Io_File();
-        if (!$io->isWriteable($path) && !$io->mkdir($path, 0777, true)) {
-            Mage::throwException(Mage::helper('catalog')->__("Cannot create writeable directory '%s'.", $path));
-        }
-    }
-
-    /**
-     * Return URL for option file download
-     *
-     * @return string
-     */
-    protected function _getOptionDownloadUrl($route, $params)
-    {
-        return Mage::getUrl($route, $params);
-    }
-
-    /**
-     * Parse file extensions string with various separators
-     *
-     * @param string $extensions String to parse
-     * @return array|null
-     */
-    protected function _parseExtensionsString($extensions)
-    {
-        preg_match_all('/[a-z0-9]+/si', strtolower($extensions), $matches);
-        if (isset($matches[0]) && is_array($matches[0]) && count($matches[0]) > 0) {
-            return $matches[0];
-        }
-        return null;
-    }
-
-    /**
-     * Simple check if file is image
-     *
-     * @param array|string $fileInfo - either file data from Zend_File_Transfer or file path
-     * @return boolean
-     */
-    protected function _isImage($fileInfo)
-    {
-        // Maybe array with file info came in
-        if (is_array($fileInfo)) {
-            return strstr($fileInfo['type'], 'image/');
-        }
-
-        // File path came in - check the physical file
-        if (!is_readable($fileInfo)) {
-            return false;
-        }
-        $imageInfo = getimagesize($fileInfo);
-        if (!$imageInfo) {
-            return false;
-        }
-        return true;
-    }
-
-    /**
-     * Max upload filesize in bytes
-     *
-     * @return int
-     */
-    protected function _getUploadMaxFilesize()
-    {
-        return min($this->_getBytesIniValue('upload_max_filesize'), $this->_getBytesIniValue('post_max_size'));
-    }
-
-    /**
-     * Return php.ini setting value in bytes
-     *
-     * @param string $ini_key php.ini Var name
-     * @return int Setting value
-     */
-    protected function _getBytesIniValue($ini_key)
-    {
-        $_bytes = @ini_get($ini_key);
-
-        // kilobytes
-        if (stristr($_bytes, 'k')) {
-            $_bytes = intval($_bytes) * 1024;
-        // megabytes
-        } elseif (stristr($_bytes, 'm')) {
-            $_bytes = intval($_bytes) * 1024 * 1024;
-        // gigabytes
-        } elseif (stristr($_bytes, 'g')) {
-            $_bytes = intval($_bytes) * 1024 * 1024 * 1024;
-        }
-        return (int)$_bytes;
-    }
-
-    /**
-     * Simple converrt bytes to Megabytes
-     *
-     * @param int $bytes
-     * @return int
-     */
-    protected function _bytesToMbytes($bytes)
-    {
-        return round($bytes / (1024 * 1024));
-    }
-}
diff --git app/code/core/Mage/Catalog/controllers/Product/CompareController.php app/code/core/Mage/Catalog/controllers/Product/CompareController.php
index 32f9b4b5bc7..30c3e99dcf9 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -80,7 +80,7 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
         }
 
         $productId = (int) $this->getRequest()->getParam('product');
-        if ($productId
+        if ($this->isProductAvailable($productId)
             && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
         ) {
             $product = Mage::getModel('catalog/product')
@@ -106,7 +106,8 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function removeAction()
     {
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -184,4 +185,15 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
         $this->_customerId = $id;
         return $this;
     }
+
+    /**
+     * Check if product is available
+     *
+     * @param int $productId
+     * @return bool
+     */
+    public function isProductAvailable($productId)
+    {
+        return Mage::getModel('catalog/product')->load($productId)->isAvailable();
+    }
 }
diff --git app/code/core/Mage/Checkout/Model/Session.php app/code/core/Mage/Checkout/Model/Session.php
index 5c17599c7fe..666dbe34bb3 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -113,13 +113,21 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             /** @var $quote Mage_Sales_Model_Quote */
             $quote = Mage::getModel('sales/quote')->setStoreId(Mage::app()->getStore()->getId());
+            $customerSession = Mage::getSingleton('customer/session');
+
             if ($this->getQuoteId()) {
                 if ($this->_loadInactive) {
                     $quote->load($this->getQuoteId());
                 } else {
                     $quote->loadActive($this->getQuoteId());
                 }
-                if ($quote->getId()) {
+                if (
+                    $quote->getId()
+                    && (
+                        ($customerSession->isLoggedIn() && $customerSession->getId() == $quote->getCustomerId())
+                        || (!$customerSession->isLoggedIn() && !$quote->getCustomerId())
+                    )
+                ) {
                     /**
                      * If current currency code of quote is not equal current currency code of store,
                      * need recalculate totals of quote. It is possible if customer use currency switcher or
@@ -136,16 +144,16 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                         $quote->load($this->getQuoteId());
                     }
                 } else {
+                    $quote->unsetData();
                     $this->setQuoteId(null);
                 }
             }
 
-            $customerSession = Mage::getSingleton('customer/session');
-
             if (!$this->getQuoteId()) {
                 if ($customerSession->isLoggedIn() || $this->_customer) {
                     $customer = ($this->_customer) ? $this->_customer : $customerSession->getCustomer();
                     $quote->loadByCustomer($customer);
+                    $quote->setCustomer($customer);
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 9185dc3f667..f7cffa3d805 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -545,7 +545,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
-        if (!$this->_validateFormKey()) {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
             return $this->_redirect('*/*');
         }
 
diff --git app/code/core/Mage/Cms/Helper/Data.php app/code/core/Mage/Cms/Helper/Data.php
index 882fa498500..a1345262d18 100644
--- app/code/core/Mage/Cms/Helper/Data.php
+++ app/code/core/Mage/Cms/Helper/Data.php
@@ -37,6 +37,7 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
     const XML_NODE_PAGE_TEMPLATE_FILTER     = 'global/cms/page/tempate_filter';
     const XML_NODE_BLOCK_TEMPLATE_FILTER    = 'global/cms/block/tempate_filter';
     const XML_NODE_ALLOWED_STREAM_WRAPPERS  = 'global/cms/allowed_stream_wrappers';
+    const XML_NODE_ALLOWED_MEDIA_EXT_SWF    = 'adminhtml/cms/browser/extensions/media_allowed/swf';
 
     /**
      * Retrieve Template processor for Page Content
@@ -74,4 +75,19 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
 
         return is_array($allowedStreamWrappers) ? $allowedStreamWrappers : array();
     }
+
+    /**
+     * Check is swf file extension disabled
+     *
+     * @return bool
+     */
+    public function isSwfDisabled()
+    {
+        $statusSwf = Mage::getConfig()->getNode(self::XML_NODE_ALLOWED_MEDIA_EXT_SWF);
+        if ($statusSwf instanceof Mage_Core_Model_Config_Element) {
+            $statusSwf = $statusSwf->asArray()[0];
+        }
+
+        return $statusSwf ? false : true;
+    }
 }
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Config.php app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
index 2b703d049fd..ebd78190fca 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
@@ -76,7 +76,8 @@ class Mage_Cms_Model_Wysiwyg_Config extends Varien_Object
             'content_css'                   =>
                 Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/content.css',
             'width'                         => '100%',
-            'plugins'                       => array()
+            'plugins'                       => array(),
+            'media_disable_flash'           => Mage::helper('cms')->isSwfDisabled()
         ));
 
         $config->setData('directives_url_quoted', preg_quote($config->getData('directives_url')));
diff --git app/code/core/Mage/Cms/etc/config.xml app/code/core/Mage/Cms/etc/config.xml
index 72b166029d9..4f046ae50df 100644
--- app/code/core/Mage/Cms/etc/config.xml
+++ app/code/core/Mage/Cms/etc/config.xml
@@ -122,7 +122,7 @@
                     </image_allowed>
                     <media_allowed>
                         <flv>1</flv>
-                        <swf>1</swf>
+                        <swf>0</swf>
                         <avi>1</avi>
                         <mov>1</mov>
                         <rm>1</rm>
diff --git app/code/core/Mage/Compiler/Model/Process.php app/code/core/Mage/Compiler/Model/Process.php
index bd40e404573..fe878024f45 100644
--- app/code/core/Mage/Compiler/Model/Process.php
+++ app/code/core/Mage/Compiler/Model/Process.php
@@ -43,6 +43,9 @@ class Mage_Compiler_Model_Process
 
     protected $_controllerFolders = array();
 
+    /** $_collectLibs library list array */
+    protected $_collectLibs = array();
+
     public function __construct($options=array())
     {
         if (isset($options['compile_dir'])) {
@@ -128,6 +131,9 @@ class Mage_Compiler_Model_Process
                 || !in_array(substr($source, strlen($source)-4, 4), array('.php'))) {
                 return $this;
             }
+            if (!$firstIteration && stripos($source, Mage::getBaseDir('lib') . DS) !== false) {
+                $this->_collectLibs[] = $target;
+            }
             copy($source, $target);
         }
         return $this;
@@ -341,6 +347,11 @@ class Mage_Compiler_Model_Process
     {
         $sortedClasses = array();
         foreach ($classes as $className) {
+            /** Skip iteration if this class has already been moved to the includes folder from the lib */
+            if (array_search($this->_includeDir . DS . $className . '.php', $this->_collectLibs)) {
+                continue;
+            }
+
             $implements = array_reverse(class_implements($className));
             foreach ($implements as $class) {
                 if (!in_array($class, $sortedClasses) && !in_array($class, $this->_processedClasses) && strstr($class, '_')) {
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index 08cb7a37246..a39578e32fe 100644
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -422,4 +422,42 @@ abstract class Mage_Core_Helper_Abstract
         }
         return $arr;
     }
+
+    /**
+     * Check for tags in multidimensional arrays
+     *
+     * @param string|array $data
+     * @param array $arrayKeys keys of the array being checked that are excluded and included in the check
+     * @param bool $skipTags skip transferred array keys, if false then check only them
+     * @return bool
+     */
+    public function hasTags($data, array $arrayKeys = array(), $skipTags = true)
+    {
+        if (is_array($data)) {
+            foreach ($data as $key => $item) {
+                if ($skipTags && in_array($key, $arrayKeys)) {
+                    continue;
+                }
+                if (is_array($item)) {
+                    if ($this->hasTags($item, $arrayKeys, $skipTags)) {
+                        return true;
+                    }
+                } elseif (
+                    (bool)strcmp($item, $this->removeTags($item))
+                    || (bool)strcmp($key, $this->removeTags($key))
+                ) {
+                    if (!$skipTags && !in_array($key, $arrayKeys)) {
+                        continue;
+                    }
+                    return true;
+                }
+            }
+            return false;
+        } elseif (is_string($data)) {
+            if ((bool)strcmp($data, $this->removeTags($data))) {
+                return true;
+            }
+        }
+        return false;
+    }
 }
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index bad4aa0cd1b..7957394c9b8 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -255,7 +255,7 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         }
         mt_srand(10000000*(double)microtime());
         for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
-            $str .= $chars[mt_rand(0, $lc)];
+            $str .= $chars[random_int(0, $lc)];
         }
         return $str;
     }
diff --git app/code/core/Mage/Core/Model/Design/Package.php app/code/core/Mage/Core/Model/Design/Package.php
index dffa4c6f50c..b7f24d177b2 100644
--- app/code/core/Mage/Core/Model/Design/Package.php
+++ app/code/core/Mage/Core/Model/Design/Package.php
@@ -567,7 +567,11 @@ class Mage_Core_Model_Design_Package
             return false;
         }
 
-        $regexps = @unserialize($configValueSerialized);
+        try {
+            $regexps = Mage::helper('core/unserializeArray')->unserialize($configValueSerialized);
+        } catch (Exception $e) {
+            Mage::logException($e);
+        }
 
         if (empty($regexps)) {
             return false;
diff --git app/code/core/Mage/Core/Model/Email/Template/Filter.php app/code/core/Mage/Core/Model/Email/Template/Filter.php
index 161893c936d..6c2c3cf4450 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -518,4 +518,24 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         }
         return $value;
     }
+
+    /**
+     * Return variable value for var construction
+     *
+     * @param string $value raw parameters
+     * @param string $default default value
+     * @return string
+     */
+    protected function _getVariable($value, $default = '{no_value_defined}')
+    {
+        Mage::register('varProcessing', true);
+        try {
+            $result = parent::_getVariable($value, $default);
+        } catch (Exception $e) {
+            $result = '';
+            Mage::logException($e);
+        }
+        Mage::unregister('varProcessing');
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
index 8525ffe03df..bda2b640ab9 100644
--- app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
+++ app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
@@ -230,8 +230,16 @@ class Mage_Core_Model_File_Validator_AvailablePath extends Zend_Validate_Abstrac
         }
 
         //validation
+        $protectedExtensions = Mage::helper('core/data')->getProtectedFileExtensions();
         $value = str_replace(array('/', '\\'), DS, $this->_value);
         $valuePathInfo = pathinfo(ltrim($value, '\\/'));
+        $fileNameExtension = pathinfo($valuePathInfo['filename'], PATHINFO_EXTENSION);
+
+        if (in_array($fileNameExtension, $protectedExtensions)) {
+            $this->_error(self::NOT_AVAILABLE_PATH, $this->_value);
+            return false;
+        }
+
         if ($valuePathInfo['dirname'] == '.' || $valuePathInfo['dirname'] == DS) {
             $valuePathInfo['dirname'] = '';
         }
diff --git app/code/core/Mage/Core/Model/Observer.php app/code/core/Mage/Core/Model/Observer.php
index 615e25d0d67..7ca983270b5 100644
--- app/code/core/Mage/Core/Model/Observer.php
+++ app/code/core/Mage/Core/Model/Observer.php
@@ -105,4 +105,19 @@ class Mage_Core_Model_Observer
         Mage::app()->getCache()->clean(Zend_Cache::CLEANING_MODE_OLD);
         Mage::dispatchEvent('core_clean_cache');
     }
+
+    /**
+     * Checks method availability for processing in variable
+     *
+     * @param Varien_Event_Observer $observer
+     * @throws Exception
+     * @return Mage_Core_Model_Observer
+     */
+    public function secureVarProcessing(Varien_Event_Observer $observer)
+    {
+        if (Mage::registry('varProcessing')) {
+            Mage::throwException(Mage::helper('core')->__('Disallowed template variable method.'));
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 1caf0e92dbd..3be2450d8db 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -146,6 +146,24 @@
                 <writer_model>Zend_Log_Writer_Stream</writer_model>
             </core>
         </log>
+        <events>
+            <model_save_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_save_before>
+            <model_delete_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_delete_before>
+        </events>
     </global>
     <frontend>
         <routers>
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index ac6cfc21b1e..fab5ba86840 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -410,3 +410,19 @@ if (!function_exists('hash_equals')) {
         return 0 === $result;
     }
 }
+
+if (version_compare(PHP_VERSION, '7.0.0', '<') && !function_exists('random_int')) {
+    /**
+     * Generates pseudo-random integers
+     *
+     * @param int $min
+     * @param int $max
+     * @return int Returns random integer in the range $min to $max, inclusive.
+     */
+    function random_int($min, $max)
+    {
+        mt_srand();
+
+        return mt_rand($min, $max);
+    }
+}
diff --git app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php
index 86cbdc1efcf..491b2118cb5 100644
--- app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php
+++ app/code/core/Mage/CurrencySymbol/Model/System/Currencysymbol.php
@@ -274,7 +274,11 @@ class Mage_CurrencySymbol_Model_System_Currencysymbol
         $result = array();
         $configData = (string)Mage::getStoreConfig($configPath, $storeId);
         if ($configData) {
-            $result = unserialize($configData);
+            try {
+                $result = Mage::helper('core/unserializeArray')->unserialize($configData);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
 
         return is_array($result) ? $result : array();
diff --git app/code/core/Mage/Downloadable/controllers/DownloadController.php app/code/core/Mage/Downloadable/controllers/DownloadController.php
index a4f019070a6..0565360a33b 100644
--- app/code/core/Mage/Downloadable/controllers/DownloadController.php
+++ app/code/core/Mage/Downloadable/controllers/DownloadController.php
@@ -96,7 +96,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $sampleId = $this->getRequest()->getParam('sample_id', 0);
         $sample = Mage::getModel('downloadable/sample')->load($sampleId);
-        if ($sample->getId()) {
+        if (
+            $sample->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $sample->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($sample->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
@@ -126,7 +131,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $linkId = $this->getRequest()->getParam('link_id', 0);
         $link = Mage::getModel('downloadable/link')->load($linkId);
-        if ($link->getId()) {
+        if (
+            $link->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $link->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($link->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
diff --git app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php
index 557b344ea68..5bb7ad46041 100644
--- app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php
+++ app/code/core/Mage/SalesRule/Model/Coupon/Massgenerator.php
@@ -79,7 +79,7 @@ class Mage_SalesRule_Model_Coupon_Massgenerator extends Mage_Core_Model_Abstract
         $code = '';
         $charsetSize = count($charset);
         for ($i=0; $i<$length; $i++) {
-            $char = $charset[mt_rand(0, $charsetSize - 1)];
+            $char = $charset[random_int(0, $charsetSize - 1)];
             if ($split > 0 && ($i % $split) == 0 && $i != 0) {
                 $char = $splitChar . $char;
             }
diff --git app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
index 085fa34ba4b..40cf7d747f2 100644
--- app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
+++ app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
@@ -118,14 +118,14 @@ class Mage_SalesRule_Model_Resource_Report_Rule_Createdat extends Mage_Reports_M
                         $adapter->getIfNullSql('base_subtotal_refunded', 0). ') * base_to_global_rate)', 0),
 
                 'discount_amount_actual'  =>
-                    $adapter->getIfNullSql('SUM((base_discount_invoiced - ' .
+                    $adapter->getIfNullSql('SUM((ABS(base_discount_invoiced) - ' .
                         $adapter->getIfNullSql('base_discount_refunded', 0) . ')
                         * base_to_global_rate)', 0),
 
                 'total_amount_actual'     =>
                     $adapter->getIfNullSql('SUM((base_subtotal_invoiced - ' .
                         $adapter->getIfNullSql('base_subtotal_refunded', 0) . ' - ' .
-                        $adapter->getIfNullSql('base_discount_invoiced - ' .
+                        $adapter->getIfNullSql('ABS(base_discount_invoiced) - ' .
                         $adapter->getIfNullSql('base_discount_refunded', 0), 0) .
                         ') * base_to_global_rate)', 0),
             );
diff --git app/code/core/Mage/Sendfriend/etc/config.xml app/code/core/Mage/Sendfriend/etc/config.xml
index 1392904ad58..1bc85b711b6 100644
--- app/code/core/Mage/Sendfriend/etc/config.xml
+++ app/code/core/Mage/Sendfriend/etc/config.xml
@@ -122,7 +122,7 @@
     <default>
         <sendfriend>
             <email>
-                <enabled>1</enabled>
+                <enabled>0</enabled>
                 <template>sendfriend_email_template</template>
                 <allow_guest>0</allow_guest>
                 <max_recipients>5</max_recipients>
diff --git app/code/core/Mage/Sendfriend/etc/system.xml app/code/core/Mage/Sendfriend/etc/system.xml
index b0d0cf16798..3a72098c94e 100644
--- app/code/core/Mage/Sendfriend/etc/system.xml
+++ app/code/core/Mage/Sendfriend/etc/system.xml
@@ -52,6 +52,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
+                            <comment><![CDATA[<strong style="color:red">Warning!</strong> This functionality is vulnerable and can be abused to distribute spam.]]></comment>
                         </enabled>
                         <template translate="label">
                             <label>Select Email Template</label>
diff --git app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
index 70e9239c5e8..c6d3874c7d4 100644
--- app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
@@ -35,7 +35,7 @@
     <div class="product-options">
         <dl>
         <?php foreach($_attributes as $_attribute): ?>
-            <dt><label class="required"><em>*</em><?php echo $_attribute->getLabel() ?></label></dt>
+            <dt><label class="required"><em>*</em><?php echo $this->escapeHtml($_attribute->getLabel()) ?></label></dt>
             <dd<?php if ($_attribute->decoratedIsLast){?> class="last"<?php }?>>
                 <div class="input-box">
                     <select name="super_attribute[<?php echo $_attribute->getAttributeId() ?>]" id="attribute<?php echo $_attribute->getAttributeId() ?>" class="required-entry super-attribute-select">
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 67761ed3406..e1627e78338 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -59,7 +59,7 @@ $_block = $this;
             <th><?php echo Mage::helper('catalog')->__('Label') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Sort Order') ?></th>
             <?php foreach ($_block->getImageTypes() as $typeId => $type): ?>
-                <th><?php echo $this->escapeHtml($type['label']); ?></th>
+                <th><?php echo $this->escapeHtml($type['label'], array('br')); ?></th>
             <?php endforeach; ?>
             <th><?php echo Mage::helper('catalog')->__('Exclude') ?></th>
             <th class="last"><?php echo Mage::helper('catalog')->__('Remove') ?></th>
diff --git app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
index 50b8cab0ac0..f9465052710 100644
--- app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
@@ -77,7 +77,7 @@
 
         <tr>
             <td class="label"><label for="inventory_min_sale_qty"><?php echo Mage::helper('catalog')->__('Minimum Qty Allowed in Shopping Cart') ?></label></td>
-            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo $this->getFieldValue('min_sale_qty')*1 ?>" <?php echo $_readonly;?>/>
+            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo (bool)$this->getProduct()->getId() ? (int)$this->getFieldValue('min_sale_qty') : Mage::helper('catalog/product')->getDefaultProductValue('min_sale_qty', $this->getProduct()->getTypeId()) ?>" <?php echo $_readonly ?>/>
 
             <?php $_checked = ($this->getFieldValue('use_config_min_sale_qty') || $this->IsNew()) ? 'checked="checked"' : '' ?>
             <input type="checkbox" id="inventory_use_config_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][use_config_min_sale_qty]" value="1" <?php echo $_checked ?> onclick="toggleValueElements(this, this.parentNode);" class="checkbox" <?php echo $_readonly;?> />
diff --git app/design/adminhtml/default/default/template/currencysymbol/grid.phtml app/design/adminhtml/default/default/template/currencysymbol/grid.phtml
index 4d76b23ca36..92fed79bfc6 100644
--- app/design/adminhtml/default/default/template/currencysymbol/grid.phtml
+++ app/design/adminhtml/default/default/template/currencysymbol/grid.phtml
@@ -66,12 +66,12 @@
                             <?php foreach($this->getCurrencySymbolsData() as $code => $data): ?>
                             <tr>
                                 <td class="label">
-                                <label for="custom_currency_symbol<?php echo $code; ?>"><?php echo $code; ?> (<?php echo $data['displayName']; ?>)</label>
+                                <label for="custom_currency_symbol<?php echo $this->escapeHtml($code); ?>"><?php echo $this->escapeHtml($code); ?> (<?php echo $this->escapeHtml($data['displayName']); ?>)</label>
                                 </td>
                                 <td class="value">
-                                    <input id="custom_currency_symbol<?php echo $code; ?>" class=" required-entry input-text" type="text" value="<?php echo Mage::helper('core')->quoteEscape($data['displaySymbol']); ?>"<?php echo $data['inherited'] ? ' disabled="disabled"' : '';?> name="custom_currency_symbol[<?php echo $code; ?>]">
-                                    &nbsp; <input id="custom_currency_symbol_inherit<?php echo $code; ?>" class="checkbox config-inherit" type="checkbox" onclick="toggleUseDefault(<?php echo '\'' . $code . '\',\'' . Mage::helper('core')->quoteEscape($data['parentSymbol'], true) . '\''; ?>)"<?php echo $data['inherited'] ? ' checked="checked"' : ''; ?> value="1" name="inherit_custom_currency_symbol[<?php echo $code; ?>]">
-                                    <label class="inherit" title="" for="custom_currency_symbol_inherit<?php echo $code; ?>"><?php echo $this->getInheritText(); ?></label>
+                                    <input id="custom_currency_symbol<?php echo $this->escapeHtml($code); ?>" class=" required-entry input-text" type="text" value="<?php echo Mage::helper('core')->quoteEscape($this->escapeHtml($data['displaySymbol'])); ?>"<?php echo $data['inherited'] ? ' disabled="disabled"' : '';?> name="custom_currency_symbol[<?php echo $this->escapeHtml($code); ?>]">
+                                    &nbsp; <input id="custom_currency_symbol_inherit<?php echo $this->escapeHtml($code); ?>" class="checkbox config-inherit" type="checkbox" onclick="toggleUseDefault(<?php echo '\'' . $this->escapeHtml($code) . '\',\'' . Mage::helper('core')->quoteEscape($data['parentSymbol'], true) . '\''; ?>)"<?php echo $data['inherited'] ? ' checked="checked"' : ''; ?> value="1" name="inherit_custom_currency_symbol[<?php echo $this->escapeHtml($code); ?>]">
+                                    <label class="inherit" title="" for="custom_currency_symbol_inherit<?php echo $this->escapeHtml($code); ?>"><?php echo $this->getInheritText(); ?></label>
                                 </td>
                             </tr>
                             <?php endforeach; ?>
diff --git app/design/adminhtml/default/default/template/customer/tab/addresses.phtml app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
index 6cd1b699e8c..bf117523044 100644
--- app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
@@ -46,7 +46,7 @@
             </a>
             <?php endif;?>
             <address>
-                <?php echo $_address->format('html') ?>
+                <?php echo $this->maliciousCodeFilter($_address->format('html')) ?>
             </address>
             <div class="address-type">
                 <span class="address-type-line">
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 8e2417100e1..ea7f2c3730f 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -75,7 +75,7 @@ $createDateStore    = $this->getStoreCreateDate();
         </table>
         <address class="box-right">
             <strong><?php echo $this->__('Default Billing Address') ?></strong><br/>
-            <?php echo $this->getBillingAddressHtml() ?>
+            <?php echo $this->maliciousCodeFilter($this->getBillingAddressHtml()) ?>
         </address>
     </fieldset>
 </div>
diff --git app/design/adminhtml/default/default/template/notification/window.phtml app/design/adminhtml/default/default/template/notification/window.phtml
index 2545eed4a71..dd0b9f6c55b 100644
--- app/design/adminhtml/default/default/template/notification/window.phtml
+++ app/design/adminhtml/default/default/template/notification/window.phtml
@@ -68,7 +68,7 @@
     </div>
     <div class="message-popup-content">
         <div class="message">
-            <span class="message-icon message-<?php echo $this->getSeverityText();?>" style="background-image:url(<?php echo $this->getSeverityIconsUrl() ?>);"><?php echo $this->getSeverityText();?></span>
+            <span class="message-icon message-<?php echo $this->getSeverityText(); ?>" style="background-image:url(<?php echo $this->escapeUrl($this->getSeverityIconsUrl()); ?>);"><?php echo $this->getSeverityText(); ?></span>
             <p class="message-text"><?php echo $this->getNoticeMessageText(); ?></p>
         </div>
         <p class="read-more"><a href="<?php echo $this->getNoticeMessageUrl(); ?>" onclick="this.target='_blank';"><?php echo $this->getReadDetailsText(); ?></a></p>
diff --git app/design/adminhtml/default/default/template/sales/order/create/data.phtml app/design/adminhtml/default/default/template/sales/order/create/data.phtml
index 92c7e267ba1..a85d1d2e7fe 100644
--- app/design/adminhtml/default/default/template/sales/order/create/data.phtml
+++ app/design/adminhtml/default/default/template/sales/order/create/data.phtml
@@ -33,7 +33,9 @@
     <?php endforeach; ?>
 </select>
 </p>
-<script type="text/javascript">order.setCurrencySymbol('<?php echo $this->getCurrencySymbol($this->getCurrentCurrencyCode()) ?>')</script>
+    <script type="text/javascript">
+        order.setCurrencySymbol('<?php echo Mage::helper('core')->jsQuoteEscape($this->getCurrencySymbol($this->getCurrentCurrencyCode())) ?>')
+    </script>
 <table cellspacing="0" width="100%">
 <tr>
     <?php if($this->getCustomerId()): ?>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index edce643a880..62e45a59dd3 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -39,9 +39,9 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
         endif; ?>
         <div class="entry-edit-head">
         <?php if ($this->getNoUseOrderLink()): ?>
-            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?> (<?php echo $_email ?>)</h4>
+            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?> (<?php echo $_email ?>)</h4>
         <?php else: ?>
-            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?></a>
+            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?></a>
             <strong>(<?php echo $_email ?>)</strong>
         <?php endif; ?>
         </div>
@@ -69,7 +69,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the New Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationChildId()) ?>">
-                    <?php echo $_order->getRelationChildRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationChildRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -77,7 +77,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the Previous Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationParentId()) ?>">
-                    <?php echo $_order->getRelationParentRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationParentRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -154,7 +154,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <div class="tools"><?php echo $this->getAddressEditLink($_order->getBillingAddress())?></div>
         </div>
         <fieldset>
-            <address><?php echo $_order->getBillingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getBillingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
@@ -167,7 +167,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <div class="tools"><?php echo $this->getAddressEditLink($_order->getShippingAddress())?></div>
         </div>
         <fieldset>
-            <address><?php echo $_order->getShippingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getShippingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
diff --git app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
index 6d6a516260d..c9a126dc641 100644
--- app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
+++ app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
@@ -38,7 +38,7 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <tr class="headings">
                 <th class="a-right">&nbsp;</th>
                 <?php $_i = 0; foreach( $this->getAllowedCurrencies() as $_currencyCode ): ?>
-                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $_currencyCode ?><strong></th>
+                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?><strong></th>
                 <?php endforeach; ?>
             </tr>
         </thead>
@@ -47,16 +47,16 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <?php if( isset($_rates[$_currencyCode]) && is_array($_rates[$_currencyCode])): ?>
                 <?php foreach( $_rates[$_currencyCode] as $_rate => $_value ): ?>
                     <?php if( ++$_j == 1 ): ?>
-                        <td class="a-right"><strong><?php echo $_currencyCode ?></strong></td>
+                        <td class="a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?></strong></td>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates) && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
                         </td>
                     <?php else: ?>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates)  && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 08a5f91260f..b765a332d22 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -42,7 +42,7 @@
 "<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>","<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>"
 "<strong>%s</strong> requests access to your account","<strong>%s</strong> requests access to your account"
 "<strong>Attention</strong>: Captcha is case sensitive.","<strong>Attention</strong>: Captcha is case sensitive."
-"A user with the same user name or email aleady exists.","A user with the same user name or email aleady exists."
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
 "API Key","API Key"
 "API Key Confirmation","API Key Confirmation"
 "ASCII","ASCII"
@@ -245,6 +245,7 @@
 "Credit memo\'s total must be positive.","Credit memo\'s total must be positive."
 "Currency","Currency"
 "Currency ""%s"" is used as %s in %s.","Currency ""%s"" is used as %s in %s."
+"Currency doesn\'t exist.","Currency doesn\'t exist."
 "Currency Information","Currency Information"
 "Currency Setup Section","Currency Setup Section"
 "Current Configuration Scope:","Current Configuration Scope:"
@@ -855,6 +856,7 @@
 "Self-assigned roles cannot be deleted.","Self-assigned roles cannot be deleted."
 "Sender","Sender"
 "Separate Email","Separate Email"
+"Serialized data is incorrect","Serialized data is incorrect"
 "Shipment #%s comment added","Shipment #%s comment added"
 "Shipment #%s created","Shipment #%s created"
 "Shipment Comments","Shipment Comments"
@@ -962,6 +964,7 @@
 "The email address is empty.","The email address is empty."
 "The email template has been deleted.","The email template has been deleted."
 "The email template has been saved.","The email template has been saved."
+"Invalid template data.","Invalid template data."
 "The flat catalog category has been rebuilt.","The flat catalog category has been rebuilt."
 "The group node name must be specified with field node name.","The group node name must be specified with field node name."
 "The image cache was cleaned.","The image cache was cleaned."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index b3515b826d2..f32be45f342 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -52,6 +52,7 @@
 "Can\'t retrieve entity config: %s","Can\'t retrieve entity config: %s"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed template variable method.","Disallowed template variable method."
 "Card type does not match credit card number.","Card type does not match credit card number."
 "Code","Code"
 "Controller file was loaded but class does not exist","Controller file was loaded but class does not exist"
diff --git app/locale/en_US/Mage_Sales.csv app/locale/en_US/Mage_Sales.csv
index 472fe0d9431..372d76d4ec3 100644
--- app/locale/en_US/Mage_Sales.csv
+++ app/locale/en_US/Mage_Sales.csv
@@ -283,6 +283,7 @@
 "Invalid draw line data. Please define ""lines"" array.","Invalid draw line data. Please define ""lines"" array."
 "Invalid entity model","Invalid entity model"
 "Invalid item option format.","Invalid item option format."
+"Invalid order data.","Invalid order data."
 "Invalid qty to invoice item ""%s""","Invalid qty to invoice item ""%s"""
 "Invalid qty to refund item ""%s""","Invalid qty to refund item ""%s"""
 "Invalid qty to ship for item ""%s""","Invalid qty to ship for item ""%s"""
diff --git app/locale/en_US/Mage_Sitemap.csv app/locale/en_US/Mage_Sitemap.csv
index 8ae5a947caf..df201861844 100644
--- app/locale/en_US/Mage_Sitemap.csv
+++ app/locale/en_US/Mage_Sitemap.csv
@@ -44,3 +44,4 @@
 "Valid values range: from 0.0 to 1.0.","Valid values range: from 0.0 to 1.0."
 "Weekly","Weekly"
 "Yearly","Yearly"
+"Please enter a sitemap name with at most %s characters.","Please enter a sitemap name with at most %s characters."
diff --git js/mage/adminhtml/wysiwyg/tiny_mce/setup.js js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
index 06b5de7ece6..812c04dedb5 100644
--- js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
+++ js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
@@ -109,6 +109,7 @@ tinyMceWysiwygSetup.prototype =
             theme_advanced_resizing : true,
             convert_urls : false,
             relative_urls : false,
+            media_disable_flash : this.config.media_disable_flash,
             content_css: this.config.content_css,
             custom_popup_css: this.config.popup_css,
             magentowidget_url: this.config.widget_window_url,
diff --git js/tiny_mce/plugins/media/js/media.js js/tiny_mce/plugins/media/js/media.js
index 45d88fe1b4b..0fbc53e88e3 100644
--- js/tiny_mce/plugins/media/js/media.js
+++ js/tiny_mce/plugins/media/js/media.js
@@ -434,7 +434,7 @@
 			html += '<select id="media_type" name="media_type" onchange="Media.formToData(\'type\');">';
 			html += option("video");
 			html += option("audio");
-			html += option("flash");
+			html += editor.getParam("media_disable_flash") ? '' : option("flash");
 			html += option("quicktime");
 			html += option("shockwave");
 			html += option("windowsmedia");
diff --git js/varien/js.js js/varien/js.js
index 3f335bf9738..199b3713bb7 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -702,3 +702,40 @@ if ((typeof Range != "undefined") && !Range.prototype.createContextualFragment)
         return frag;
     };
 }
+
+/**
+ * Create form element. Set parameters into it and send
+ *
+ * @param url
+ * @param parametersArray
+ * @param method
+ */
+Varien.formCreator = Class.create();
+Varien.formCreator.prototype = {
+    initialize : function(url, parametersArray, method) {
+        this.url = url;
+        this.parametersArray = JSON.parse(parametersArray);
+        this.method = method;
+        this.form = '';
+
+        this.createForm();
+        this.setFormData();
+    },
+    createForm : function() {
+        this.form = new Element('form', { 'method': this.method, action: this.url });
+    },
+    setFormData : function () {
+        for (var key in this.parametersArray) {
+            Element.insert(
+                this.form,
+                new Element('input', { name: key, value: this.parametersArray[key], type: 'hidden' })
+            );
+        }
+    }
+};
+
+function customFormSubmit(url, parametersArray, method) {
+    var createdForm = new Varien.formCreator(url, parametersArray, method);
+    Element.insert($$('body')[0], createdForm.form);
+    createdForm.form.submit();
+}
diff --git lib/phpseclib/PHP/Compat/Function/array_fill.php lib/phpseclib/PHP/Compat/Function/array_fill.php
index 79b5312aa2d..7eb231a0962 100644
--- lib/phpseclib/PHP/Compat/Function/array_fill.php
+++ lib/phpseclib/PHP/Compat/Function/array_fill.php
@@ -14,6 +14,7 @@
  * @version     $Revision: 1.1 $
  * @since       PHP 4.2.0
  */
+/*
 function php_compat_array_fill($start_index, $num, $value)
 {
     if ($num <= 0) {
@@ -39,3 +40,4 @@ if (!function_exists('array_fill')) {
         return php_compat_array_fill($start_index, $num, $value);
     }
 }
+*/
diff --git lib/phpseclib/PHP/Compat/Function/bcpowmod.php lib/phpseclib/PHP/Compat/Function/bcpowmod.php
index 4c162b87ef6..0366fef84d4 100644
--- lib/phpseclib/PHP/Compat/Function/bcpowmod.php
+++ lib/phpseclib/PHP/Compat/Function/bcpowmod.php
@@ -15,6 +15,7 @@
  * @since       PHP 5.0.0
  * @require     PHP 4.0.0 (user_error)
  */
+/*
 function php_compat_bcpowmod($x, $y, $modulus, $scale = 0)
 {
     // Sanity check
@@ -64,3 +65,4 @@ if (!function_exists('bcpowmod')) {
         return php_compat_bcpowmod($x, $y, $modulus, $scale);
     }
 }
+*/
diff --git lib/phpseclib/PHP/Compat/Function/str_split.php lib/phpseclib/PHP/Compat/Function/str_split.php
index 8f5179bc988..607e5ca32c4 100644
--- lib/phpseclib/PHP/Compat/Function/str_split.php
+++ lib/phpseclib/PHP/Compat/Function/str_split.php
@@ -12,6 +12,7 @@
  * @since       PHP 5
  * @require     PHP 4.0.0 (user_error)
  */
+/*
 function php_compat_str_split($string, $split_length = 1)
 {
     if (!is_scalar($split_length)) {
@@ -57,3 +58,4 @@ if (!function_exists('str_split')) {
         return php_compat_str_split($string, $split_length);
     }
 }
+*/
