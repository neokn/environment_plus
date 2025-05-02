import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("development") {
            dimension = "flavor-type"
            applicationId = "pro.modernwizard.environmentPlusExample"
            resValue(type = "string", name = "app_name", value = "env+")
            resValue(type = "string", name = "flutter_flavor", value = "development")
        }
        create("production") {
            dimension = "flavor-type"
            applicationId = "pro.modernwizard.environmentPlusExample"
            resValue(type = "string", name = "app_name", value = "env+")
            resValue(type = "string", name = "flutter_flavor", value = "production")
        }
    }
}