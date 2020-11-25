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

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// VirtualMobilePhoneSpec defines the desired state of VirtualMobilePhone
type VirtualMobilePhoneSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file

	CPU    string `json:"cpu"`
	Memory string `json:"memory"`
	HOST   string `json:"host"`
	Size   int32  `json:"size,omitempty"`
	// StartAndriodID int    `json:"start_andriod_id"`
	// EndAndriodID   int    `json:"end_andriod_id"`
}

// VirtualMobilePhoneStatus defines the observed state of VirtualMobilePhone
type VirtualMobilePhoneStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
	Status string   `json:"status"`
	Phones []string `json:"phones"`
}

// +kubebuilder:object:root=true
// +kubebuilder:subresource:status

// VirtualMobilePhone is the Schema for the virtualmobilephones API
type VirtualMobilePhone struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   VirtualMobilePhoneSpec   `json:"spec,omitempty"`
	Status VirtualMobilePhoneStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// VirtualMobilePhoneList contains a list of VirtualMobilePhone
type VirtualMobilePhoneList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []VirtualMobilePhone `json:"items"`
}

func init() {
	SchemeBuilder.Register(&VirtualMobilePhone{}, &VirtualMobilePhoneList{})
}
