# Adding your LDAPS certificate to Harbor in TKG

>Note: in the following example, the Harbor package is installed in the `tkg-packages` namespace. If your Harbor package is installed in a different namspace, specify your namespace.

1. Modify the `overlay-harbor-ldaps-cert.yaml` overlay file and set your LDAPS/CA certificate for the `ca.crt` parameter under the `harbor-ldaps-cert` secret.

    >**Important note: the overlay file contains an extra empty line at the end. This is part of the `ca.crt` value and you must keep this line. Otherwise, Harbor will run into issues reading the certificate.**

2. On your TKG cluster, create a secret from the `overlay-harbor-ldaps-cert.yaml` file:

    ```bash
    kubectl create secret generic overlay-harbor-ldaps-cert -n tkg-packages \
    --from-file=overlay-harbor-ldaps-cert.yaml \
    -o yaml --dry-run=client | kubectl apply -f -
    ```

3. Annotate the `harbor` package with the overlay:

    ```bash
    kubectl annotate packageinstalls harbor \
    ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=overlay-harbor-ldaps-cert \
    -n tkg-packages
    ```

4. Trigger reconcilation for the package and wait for the package to reconcile.

   ```bash
   kctrl app kick -a harbor -n tkg-packages -y
   ```

5. Confirm that the package has sucessfully reconciled.

    ```bash
    kubectl get app harbor -n tkg-packages
    ```
