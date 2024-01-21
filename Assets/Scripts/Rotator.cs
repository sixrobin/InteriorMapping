namespace InteriorMapping
{
    using UnityEngine;

    [DisallowMultipleComponent]
    public class Rotator : MonoBehaviour
    {
        private enum E_Axis
        {
            [InspectorName("None")]
            NONE,
            X,
            Y,
            Z,
        }

        [SerializeField]
        private E_Axis axis = E_Axis.Z;

        [SerializeField]
        private Space space = Space.Self;

        [SerializeField]
        private Vector2 rotationSpeedMinMax = new(90f, 90f);

        [SerializeField]
        private bool clockwise = true;

        private Quaternion initRotation;
        private float rotationSpeed;

        private void ResetRotation()
        {
            this.transform.rotation = this.initRotation;
        }

        private void RotateContinuous()
        {
            float speed = this.rotationSpeed * Time.deltaTime;
            if (this.clockwise)
                speed = -speed;

            Vector3 rotation = this.axis switch
            {
                E_Axis.X => new Vector3(speed, 0f, 0f),
                E_Axis.Y => new Vector3(0f, speed, 0f),
                E_Axis.Z => new Vector3(0f, 0f, speed),
                _ => Vector3.zero,
            };

            this.transform.Rotate(rotation, this.space);
        }

        #region UNITY FUNCTIONS

        private void Start()
        {
            this.initRotation = this.transform.rotation;
            this.rotationSpeed = Random.Range(this.rotationSpeedMinMax.x, this.rotationSpeedMinMax.y);

            float randomStartRotation = Random.Range(0f, 360f);
            Vector3 rotation = this.axis switch
            {
                E_Axis.X => new Vector3(randomStartRotation, 0f, 0f),
                E_Axis.Y => new Vector3(0f, randomStartRotation, 0f),
                E_Axis.Z => new Vector3(0f, 0f, randomStartRotation),
                _ => Vector3.zero,
            };

            this.transform.Rotate(rotation, this.space);
        }

        private void Update()
        {
            if (this.axis != E_Axis.NONE)
                this.RotateContinuous();
        }

        #endregion // UNITY FUNCTIONS
    }
}