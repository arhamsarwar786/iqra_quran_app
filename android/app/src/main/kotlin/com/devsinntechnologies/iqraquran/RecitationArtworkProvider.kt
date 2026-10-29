package com.devsinntechnologies.iqraquran

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File
import java.io.FileNotFoundException

// Serves the recitation artwork to the system media controls (notification,
// lock screen, Android Auto/Wear). They run in other processes and cannot read
// the app's private files, so the artwork is shared through this read-only
// provider. It serves this one bundled image and nothing else.
class RecitationArtworkProvider : ContentProvider() {

    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String = "image/png"

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r" || uri.lastPathSegment != FILE_NAME) {
            throw FileNotFoundException(uri.toString())
        }
        return ParcelFileDescriptor.open(artworkFile(), ParcelFileDescriptor.MODE_READ_ONLY)
    }

    // Callers need a whole file descriptor, so the raw resource is copied out
    // once, and again after an app update changes it.
    @Synchronized
    private fun artworkFile(): File {
        val context = context ?: throw FileNotFoundException(FILE_NAME)
        val file = File(context.noBackupFilesDir, FILE_NAME)
        val expectedLength = context.resources.openRawResourceFd(R.raw.recitation_artwork)
            .use { it.length }
        if (!file.exists() || file.length() != expectedLength) {
            val temp = File(file.path + ".tmp")
            context.resources.openRawResource(R.raw.recitation_artwork).use { input ->
                temp.outputStream().use { input.copyTo(it) }
            }
            if (!temp.renameTo(file)) throw FileNotFoundException(FILE_NAME)
        }
        return file
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? = null

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    private companion object {
        const val FILE_NAME = "recitation_artwork.png"
    }
}
