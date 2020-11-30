/*
Copyright 2020 qiuwenqi.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	"fmt"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/api/resource"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"reflect"
	"strconv"

	"github.com/go-logr/logr"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	infrav1 "virtualmobilephone/api/v1"
)

// VirtualMobilePhoneReconciler reconciles a VirtualMobilePhone object
type VirtualMobilePhoneReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// +kubebuilder:rbac:groups=infra.qiuwenqi.com,resources=virtualmobilephones,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=infra.qiuwenqi.com,resources=virtualmobilephones/status,verbs=get;update;patch

// Reconcile reconciles VirtualMobilePhone object
func (r *VirtualMobilePhoneReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.Background()
	log := r.Log.WithValues("virtualmobilephone", req.NamespacedName)

	virtualMobilePhone := &infrav1.VirtualMobilePhone{}

	// Fetch the VirtualMobilePhone instance
	err := r.Get(ctx, req.NamespacedName, virtualMobilePhone)
	if err != nil {
		if errors.IsNotFound(err) {
			// Request object not found, could have been deleted after reconcile request.
			// Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
			// Return and don't requeue
			log.Info("VirtualMobilePhone resource not found. Ignoring since object must be deleted")
			return ctrl.Result{}, nil
		}
		// Error reading the object - requeue the request.
		log.Error(err, "Failed to get VirtualMobilePhone")
		return ctrl.Result{}, err
	}

	// Check if the deployment already exists, if not create a new one
	found := &appsv1.Deployment{}
	err = r.Get(ctx, types.NamespacedName{Name: virtualMobilePhone.Name, Namespace: virtualMobilePhone.Namespace}, found)
	if err != nil && errors.IsNotFound(err) {
		// Define a new deployment
		dep := r.deploymentForVirtualMobilePhone(virtualMobilePhone)
		log.Info("Creating a new Deployment", "Deployment.Namespace",
			dep.Namespace, "Deployment.Name", dep.Name)
		err = r.Create(ctx, dep)
		if err != nil {
			log.Error(err, "Failed to create new Deployment", "Deployment.Namespace",
				dep.Namespace, "Deployment.Name", dep.Name)
			return ctrl.Result{}, err
		}
		// Deployment created successfully - return and requeue
		return ctrl.Result{Requeue: true}, nil
	} else if err != nil {
		log.Error(err, "Failed to get Deployment")
		return ctrl.Result{}, err
	}

	// Ensure the deployment size is the same as the spec
	size := virtualMobilePhone.Spec.Size
	if *found.Spec.Replicas != size {
		found.Spec.Replicas = &size
		err = r.Update(ctx, found)
		if err != nil {
			log.Error(err, "Failed to update Deployment", "Deployment.Namespace",
				found.Namespace, "Deployment.Name", found.Name)
			return ctrl.Result{}, err
		}
		// Spec updated - return and requeue
		return ctrl.Result{Requeue: true}, nil
	}

	// Update the VirtualMobilePhone status with the pod names
	// List the pods for this virtualMobilePhone's deployment
	podList := &corev1.PodList{}
	listOpts := []client.ListOption{
		client.InNamespace(virtualMobilePhone.Namespace),
		client.MatchingLabels(labelsForVirtualMobilePhone(virtualMobilePhone.Name)),
	}
	if err = r.List(ctx, podList, listOpts...); err != nil {
		log.Error(err, "Failed to list pods", "VirtualMobilePhone.Namespace",
			virtualMobilePhone.Namespace, "VirtualMobilePhone.Name", virtualMobilePhone.Name)
		return ctrl.Result{}, err
	}
	podNames := getPodNames(podList.Items)

	// Update status.Nodes if needed
	if !reflect.DeepEqual(podNames, virtualMobilePhone.Status.Phones) {
		virtualMobilePhone.Status.Phones = podNames
		err := r.Status().Update(ctx, virtualMobilePhone)
		if err != nil {
			log.Error(err, "Failed to update VirtualMobilePhone status")
			return ctrl.Result{}, err
		}
	}

	return ctrl.Result{}, nil
}

// SetupWithManager setupWithManager
func (r *VirtualMobilePhoneReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&infrav1.VirtualMobilePhone{}).
		Owns(&appsv1.Deployment{}).
		Complete(r)
}

var (
	quantity = *resource.NewQuantity(1, resource.DecimalSI)
)

// deploymentForVirtualMobilePhone returns a virtualMobilePhone Deployment object
func (r *VirtualMobilePhoneReconciler) deploymentForVirtualMobilePhone(m *infrav1.VirtualMobilePhone) *appsv1.Deployment {
	ls := labelsForVirtualMobilePhone(m.Name)
	replicas := m.Spec.Size
	terminationGracePeriodSeconds := int64(3)
	androidName := m.Name
	nodeName := m.Spec.HOST
	vncPort := strconv.FormatInt(int64(m.Spec.VNCPort), 10)
	adbPort := strconv.FormatInt(int64(m.Spec.ADBPort), 10)
	screenWidth := strconv.FormatInt(int64(m.Spec.ScreenWidth), 10)
	screenHeigth := strconv.FormatInt(int64(m.Spec.ScreenHeigth), 10)
	imageURL := m.Spec.Image
	androidIDX := strconv.FormatInt(int64(m.Spec.AndriodIDX), 10)
	cpuRequest := m.Spec.CPU
	memRequest := m.Spec.Memory

	dep := &appsv1.Deployment{
		ObjectMeta: metav1.ObjectMeta{
			Name:      m.Name,
			Namespace: m.Namespace,
		},
		Spec: appsv1.DeploymentSpec{
			Replicas: &replicas,
			Selector: &metav1.LabelSelector{
				MatchLabels: ls,
			},
			Template: corev1.PodTemplateSpec{
				ObjectMeta: metav1.ObjectMeta{
					Labels: ls,
					Name:   androidName,
					Annotations: map[string]string{
						"container.apparmor.security.beta.kubernetes.io/android": "unconfined",
						"container.seccomp.security.alpha.kubernetes.io/android": "localhost/android.json"},
				},
				Spec: corev1.PodSpec{
					NodeName:                      nodeName,
					TerminationGracePeriodSeconds: &terminationGracePeriodSeconds,
					Tolerations: []corev1.Toleration{
						{Key: "node-role.kubernetes.io/master",
							Effect: corev1.TaintEffectNoSchedule},
					},
					InitContainers: []corev1.Container{{
						Name:            "init-android",
						Image:           "busybox",
						ImagePullPolicy: corev1.PullIfNotPresent,
						Command:         []string{"/openvmi/android-cfg-init.sh"},
						Resources: corev1.ResourceRequirements{
							Limits: corev1.ResourceList{
								"openvmi/binder": quantity,
							},
						},
						VolumeMounts: []corev1.VolumeMount{
							{Name: "volume-openvmi",
								MountPath: "/openvmi",
							},
						},
						Env: []corev1.EnvVar{
							{Name: "ANDROID_NAME", Value: androidName},
							{Name: "ANDROID_IDX", Value: androidIDX},
							{Name: "ANDROID_VNC_PORT", Value: vncPort},
							{Name: "ANDROID_ADB_PORT", Value: adbPort},
							{Name: "ANDROID_SCREEN_WIDTH", Value: screenWidth},
							{Name: "ANDROID_SCREEN_HEIGHT", Value: screenHeigth},
						},
					}},
					Containers: []corev1.Container{
						{
							Image:           imageURL,
							ImagePullPolicy: corev1.PullIfNotPresent,
							Resources: corev1.ResourceRequirements{
								Limits: corev1.ResourceList{
									corev1.ResourceName(corev1.ResourceCPU):    resource.MustParse(cpuRequest),
									corev1.ResourceName(corev1.ResourceMemory): resource.MustParse(memRequest),
									"openvmi/fuse":   quantity,
									"openvmi/ashmem": quantity,
									"openvmi/binder": quantity,
								},
								Requests: corev1.ResourceList{
									corev1.ResourceName(corev1.ResourceCPU):    resource.MustParse("1"),
									corev1.ResourceName(corev1.ResourceMemory): resource.MustParse("1024Mi"),
								},
							},
							Name:    "android",
							Command: []string{"/openvmi-init.sh"},
							SecurityContext: &corev1.SecurityContext{
								Capabilities: &corev1.Capabilities{
									Add: []corev1.Capability{"SYS_ADMIN", "NET_ADMIN", "SYS_MODULE", "SYS_NICE", "SYS_TIME", "SYS_TTY_CONFIG", "NET_BROADCAST", "IPC_LOCK", "SYS_RESOURCE"},
								},
							},
							Env: []corev1.EnvVar{
								{Name: "ANDROID_NAME", Value: ""},
								{Name: "PATH", Value: "/system/bin:/system/xbin"},
								{Name: "ANDROID_DATA", Value: "/data"},
							},
							Lifecycle: &corev1.Lifecycle{
								PreStop: &corev1.Handler{Exec: &corev1.ExecAction{Command: []string{
									"/openvmi/android-env-uninit.sh",
								}}},
							},
							ReadinessProbe: &corev1.Probe{
								InitialDelaySeconds: 5,
								PeriodSeconds:       2,
								TimeoutSeconds:      1,
								SuccessThreshold:    1,
								FailureThreshold:    30,
								Handler: corev1.Handler{Exec: &corev1.ExecAction{Command: []string{
									"sh", "-c", "getprop sys.boot_completed | grep 1"}}},
							},
							VolumeMounts: []corev1.VolumeMount{
								{Name: "volume-openvmi", MountPath: "/openvmi"},
								{Name: "volume-pipe", MountPath: "/dev/qemu_pipe"},
								{Name: "volume-bridge", MountPath: "/dev/openvmi_bridge:rw"},
								{Name: "volume-event0", MountPath: "/dev/input/event0:rw"},
								{Name: "volume-event1", MountPath: "/dev/input/event1:rw"},
								{Name: "volume-event2", MountPath: "/dev/input/event2:rw"},
								{Name: "volume-data", MountPath: "/data:rw"},
								{Name: "volume-tun", MountPath: "/dev/tun:rw"},
							},
						},
					},
					Volumes: []corev1.Volume{
						{Name: "volume-openvmi", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: "/opt/openvmi/android-env/docker",
							},
						}},
						{Name: "volume-pipe", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: fmt.Sprintf("/opt/openvmi/android-socket/%s/sockets/qemu_pipe", androidName),
							},
						}},
						{Name: "volume-bridge", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: fmt.Sprintf("/opt/openvmi/android-socket/%s/sockets/openvmi_bridge", androidName),
							},
						}},
						{Name: "volume-event0", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: fmt.Sprintf("/opt/openvmi/android-socket/%s/input/event0", androidName),
							},
						}},
						{Name: "volume-event1", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: fmt.Sprintf("/opt/openvmi/android-socket/%s/input/event1", androidName),
							},
						}},
						{Name: "volume-event2", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: fmt.Sprintf("/opt/openvmi/android-socket/%s/input/event2", androidName),
							},
						}},
						{Name: "volume-data", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: fmt.Sprintf("/opt/openvmi/android-data/%s/data", androidName),
							},
						}},
						{Name: "volume-tun", VolumeSource: corev1.VolumeSource{
							HostPath: &corev1.HostPathVolumeSource{
								Path: "/dev/net/tun",
							},
						}},
					},
				},
			},
		},
	}
	// Set VirtualMobilePhone instance as the owner and controller
	ctrl.SetControllerReference(m, dep, r.Scheme)
	return dep
}

// labelsForVirtualMobilePhone returns the labels for selecting the resources
// belonging to the given virtualMobilePhone CR name.
func labelsForVirtualMobilePhone(name string) map[string]string {
	return map[string]string{"app": "virtualMobilePhone", "android_name": name}
}

// getPodNames returns the pod names of the array of pods passed in
func getPodNames(pods []corev1.Pod) []string {
	var podNames []string
	for _, pod := range pods {
		podNames = append(podNames, pod.Name)
	}
	return podNames
}
